@secure()
param sqsQueueUrl string

@secure()
param awsAccessKeyId string

@secure()
param awsSecretAccessKey string

param deploymentName string = utcNow()

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-sqs-${uniqueString(deployment().name)}'
  location: deployment().location
}

module app 'app.bicep' = {
  scope: rg
  name: deploymentName
  params: {
    awsAccessKeyId: awsAccessKeyId
    awsSecretAccessKey: awsSecretAccessKey
    sqsQueueUrl: sqsQueueUrl
  }
}

output resourceGroupName string = rg.name
