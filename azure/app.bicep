@secure()
param sqsQueueUrl string

@secure()
param awsAccessKeyId string

@secure()
param awsSecretAccessKey string

resource sb 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: 'sb-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }

  resource auth 'AuthorizationRules' = {
    name: 'LogicApp'
    properties: {
      rights: [
        'Send'
      ]
    }
  }

  resource queue 'queues' = {
    name: 'sbq-${uniqueString(resourceGroup().id)}'
  }
}

var sbApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceGroup().location, 'servicebus')
resource serviceBusConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'connection-servicebus'
  location: resourceGroup().location
  properties: {
    displayName: 'Azure Service Bus'
    api: {
      id: sbApiId
    }
    parameterValues: {
      connectionString: sb::auth.listKeys().primaryConnectionString
    }
  }
}

var sqsApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceGroup().location, 'amazonsqs')
resource sqsConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'connection-sqs'
  location: resourceGroup().location
  properties: {
    displayName: 'Amazon SQS'
    api: {
      id: sqsApiId
    }
    parameterValues: {
      accessKeyId: awsAccessKeyId
      accessKeySecret: awsSecretAccessKey
      queueUrl: sqsQueueUrl
    }
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          type: 'Object'
        }
      }
      triggers: {
        message_is_received_from_sqs: {
          type: 'ApiConnection'
          recurrence: {
            interval: 15
            frequency: 'Second'
          }
          evaluatedRecurrence: {
            interval: 15
            frequency: 'Second'
          }
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sqs\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/message'
            queries: {
              requestWaitTimeoutSeconds: 0
            }
          }
        }
      }
      actions: {
        send_message_to_servicebus: {
          type: 'ApiConnection'
          inputs: {
            body: {
              ContentData: '@{encodeBase64(triggerBody()?[\'content\'])}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(\'${sb::queue.name}\')}/messages'
            queries: {
              systemProperties: 'None'
            }
          }
        }
        delete_message_from_sqs: {
          type: 'ApiConnection'
          runAfter: {
            send_message_to_servicebus: [
              'Succeeded'
            ]
          }
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sqs\'][\'connectionId\']'
              }
            }
            method: 'delete'
            path: '/message'
            queries: {
              messageReceiptHandle: '@triggerBody()?[\'receiptHandle\']'
            }
          }
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          sqs: {
            id: sqsApiId
            connectionId: sqsConnection.id
            connectionName: 'Amazon SQS connection'
          }
          servicebus: {
            id: sbApiId
            connectionId: serviceBusConnection.id
            connectionName: 'Azure Service Bus connection'
          }
        }
      }
    }
  }
}
