# Factory Integration

## Introduction and intended use

Factory accounts are used to build custom data & analytics solutions in UPTIMIZE, using the full flexibility of available AWS services.
Oftentimes, these use cases also require the deployment of custom frontends - leveraging the app service to minimize the administrative and operational burden is desirable. The app service - factory integration allows data practitioners to do exactly that, in a secure and self-service way.

Here are some examples what could be build with the factory integration:

* Submitting **batch jobs** to a factory accounts batch job queue and using **Lambda Functions** to manage these jobs from the frontend.
* Using a **S3 Bucket** as storage backend for your application.
* Using a **DynamoDB** table as persistence layer for your app.

## Architecture

![Architecture](https://docs.uptimize.merckgroup.com/docs-assets/app-service/factory-integration-architecture.png)

1. If the owner of an app enables the factory integration by selecting an AWS Account in the app configuration, the app service automatically creates a task role for the app container. This task role allows the running container to assume roles in the enabled factory accounts (i.e. Resource: `arn:aws:iam::987654321:role/*`). Note, that this, without step 2, does not allow to execute any actions on the factory account.

2. After the app and the task role (i.e. `TaskRole`) is created, the factory admin can create a factory role (for example `FactoryRole`) in the Factory Account. This role needs to be created with a **Trust Relationship** to the task role: the target factory account creates an IAM Trust policy allowing the task role of the app service app to assume the well-defined task role (i.e. `arn:aws:iam::123456789:role/TaskRole1P06WU2CW86XD`) in the factory account.

3. The app service app can then **assume** the role via STS (e.g. using `boto3`) resulting in temporary credentials that can be used to trigger actions in the target factory account. The allowed actions are controlled by the policies attached to the factory role in the factory account. I.e. the app service cannot use this mechanism to perform operations in the factory account that have not been explicitly whitelisted.

## Example Integration

The following Python snippet calls a Lambda function deployed in a Factory account. The code first retrieves the `FactoryRole` using the sts-boto3 client. To improve performance, this call is cached for 1 hour using the `@cached` decorator from the `cachetools` package. Note that `boto3` is able to retrieve the credentials of the task role automatically from the [environment](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html) of the container.

Afterwards, the credentials are used to construct an instance of a `boto3.client("lambda")` client. This client is used to invoke a lambda function and print the response.


```python
from cachetools import TTLCache, cached
import boto3
import time

@cached(cache=TTLCache(maxsize=1, ttl=3600))
def assume_role_in_factory_account(role_arn: str) -> dict:
    sts = boto3.client("sts", endpoint_url="https://sts.eu-central-1.amazonaws.com")
    response = sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName=f"fromAppService-{int(time.time() * 1000)}",
        DurationSeconds=3600,
    )
    credentials = response["Credentials"]
    expiration = credentials['Expiration'].isoformat()
    print(f"Retrieved credentials for {role_arn=} {expiration=}")
    return {
        "aws_access_key_id": credentials["AccessKeyId"],
        "aws_secret_access_key": credentials["SecretAccessKey"],
        "aws_session_token": credentials["SessionToken"],
    }

def get_lambda_client(role_arn: str):
    return boto3.client("lambda", **assume_role_in_factory_account(role_arn=role_arn))

if __name__ == '__main__':
    lambda_client = get_lambda_client(role_arn='arn:aws:iam::123456789:role/TaskRole1P06WU2CW86XD')
    response = lambda_client.invoke(
        FunctionName="arn:aws:lambda:eu-central-1:987654321:function:LambdaFunctionInFactoryAccount",
        Payload=score_request.json().encode("UTF-8"),
    )
    if response["StatusCode"] == 200:
        print(json.loads(response["Payload"].read().decode("UTF-8")))

```

The following factory role is created as a pre-requisite in the factory account. The required `TaskRoleArn` of the app can be copied from the **Change app configuration** dialog within the app service UI:

```yaml
FactoryRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Statement:
      - Effect: Allow
        Principal:
          AWS: 'arn:aws:iam::123456789:role/TaskRole1P06WU2CW86XD'
        Action: 'sts:AssumeRole'
    Policies:
      - PolicyName: AllowLambaInvoke
        PolicyDocument:
          Statement:
          - Effect: Allow
            Action:
              - 'lambda:InvokeFunction'
            Resource: 
              - 'arn:aws:lambda:eu-central-1:987654321:function:LambdaFunctionInFactoryAccount'
```


## List of enabled AWS Services / Endpoints

* STS
* S3
* Lambda
* DynamoDB
* API Gateway
* Athena
* Secrets Manager

If your use case architecture requires other AWS Service Endpoints, please create an Item in the UPTIMIZE [AWS Team Board](https://dev.azure.com/Uptimize/UPTIMIZE-AWS/_boards/board/t/UPTIMIZE-AWS%20Team/Issues) and the team will review your request.