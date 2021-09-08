@secure()
param sqsQueueUrl string

@secure()
param awsAccessKeyId string

@secure()
param awsSecretAccessKey string

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-sqs-${uniqueString(deployment().name)}'
  location: deployment().location
}

module app 'app.bicep' = {
  scope: rg
  name: 'app'
  params: {
    awsAccessKeyId: awsAccessKeyId
    awsSecretAccessKey: awsSecretAccessKey
    sqsQueueUrl: sqsQueueUrl
  }
}
