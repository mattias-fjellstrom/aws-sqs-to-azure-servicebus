# Send messages from AWS SQS to Azure Service Bus

This example demonstrates how to send messages from an SQS queue in AWS to a Service Bus queue in Azure.

## Prerequisites

- AWS CLI with a default profile and default region configured ([install](https://aws.amazon.com/cli/))
- Azure CLI with a default subscription set ([install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Azure Bicep CLI (install with `az bicep install`)

## Deploy AWS resources

The provided CloudFormation template creates an IAM user with access keys, and an SQS queue. If you already have a user and a queue you want to use, go ahead and use them instead but update the following commands accordingly.

```bash
stackName=azure
aws cloudformation deploy \
    --stack-name $stackName \
    --template-file ./aws/deployment.yml \
    --capabilities CAPABILITY_IAM

sqsUrl=$(aws cloudformation describe-stacks \
    --stack-name $stackName \
    --query 'Stacks[].Outputs[?OutputKey==`SqsQueueUrl`].OutputValue' \
    --output text)

accessKeyId=$(aws cloudformation describe-stacks \
    --stack-name $stackName \
    --query 'Stacks[].Outputs[?OutputKey==`AccessKeyId`].OutputValue' \
    --output text)

secretAccessKey=$(aws cloudformation describe-stacks \
    --stack-name $stackName \
    --query 'Stacks[].Outputs[?OutputKey==`SecretAccessKey`].OutputValue' \
    --output text)
```

## Deploy Azure resources

Deploy a resource group, a service bus namespace and queue, and a logic app with the required connections.

```bash
az deployment sub create \
    --name my-deployment \
    --location northeurope \
    --template-file ./azure/main.bicep \
    --parameters sqsQueueUrl=$sqsUrl awsAccessKeyId=$accessKeyId awsSecretAccessKey=$secretAccessKey
```

## Test

### Send a message to the SQS queue

```bash
aws sqs send-message --queue-url $sqsUrl --message-body "This is my message"
```

### Verify message has arrived in Service Bus queue

Unfortunately there is no support for data-plane operations using the Azure CLI, so instead do the following:

1. Go to the Azure portal
1. Open your Service Bus namespace
1. Click on _queues_ and open the only queue in the list
1. Open _Service Bus Explorer_ for the queue
1. Click on the _Receive_ tab and then on the _Receive_ button
1. The message is displayed below, click on it and the message content is displayed

![Service Bus Explorer](./assets/azureportal.png)
