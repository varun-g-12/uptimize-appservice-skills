# Best Practices and Guidelines

## Data Access

With the App Service you can access all your data in UPTIMIZE Foundry. Please use the **Foundry DevTools library** to read and write data. For a reference how to use the Foundry DevTools library please head to this [page](https://docs.uptimize.merckgroup.com/lab/data/how-to-read-and-write-data/). Additionally, in our **Streamlit example App** (screenshot below) you can also find some code on how to read & write Foundry data. The other example apps also contain sample code to interact with Foundry.

If you like to leverage own solutions to request data from Foundry, the App Service Load Balancer will automatically insert the Foundry user token into the http request header `x-foundry-accesstoken`. You can extract the token from the incoming http request and use it to perform requests to Foundry. For Dash and Streamlit, the **Foundry DevTools library** will automatically extract the User Foundry Token from the header.

![streamlit-example](https://docs.uptimize.merckgroup.com/docs-assets/workbenches/streamlit-example.png)


## Quota Request Process

We have put some user based quotas in place to ensure good performance and cost efficiency of the App Service. Per user we allow **5 Apps** by default and we also have a fixed limit on compute and memory across a user´s Apps.

### How to Request Quotas?
Please use the link to raise a quota access request: [AppService User Quota Request Form](https://palantir.mcloud.merckgroup.com/workspace/module/view/latest/ri.workshop.main.module.d7a8d0cd-49cc-49a9-b1b6-6aec4986614f)
The below screenshot shows the quota request form. As a user, you can request your quota request increase.

![Quota Request Form](https://docs.uptimize.merckgroup.com/assets/quota-request-form.png)

- **Request Type:**
  * The request type is the type of the quota you want to increase, either AppService Apps or DBaaS Databases. Please select any one option.
  * Once you have selected the option, "What is the required number of AppService Apps/DBaaS Databases that needs to be increased" option will be visible. Here, please select the number of apps you want to increase.


- **Reason for the Request:** Provide an appropriate reason for the request and submit. Once submitted, you will receive a notification on successful submission.

### Action from the SDOs
Whenever a quota request is submitted by the user, if the quota for the AppService Apps is more than or equal to 10 or for the DBaaS Databases is more than or equal to 2, then this will go for the user's sector SDO's approval.

As a sector SDO, you will receive a notification on quota approval that needs to be reviewed and approved. Once approved by SDOs, then the request should be approved by the AppService Admin team.

The screenshot below provides the user quota information for the approver, including the total current quota and the requested quota details.

![Quota Details](https://docs.uptimize.merckgroup.com/assets/quota-details.png)

## Transfer Orphan Apps Ownership[Experimental Feature]
We have introduced a new Orphan Apps feature to help manage app that were previously owned by users who are no longer part of the organization. These app currently do not have valid ownership, which may cause maintenance, access, and governance issues.
 
As a user, you have permission to check if any orphan apps are present for your use cases and transfer ownership of those orphan apps to yourself.
 
**Note: This feature is currently experimental and is enabled by request only. To get access, please reach out to ahmed.aladeeb@merckgroup.com**
 
### How it works
* First, click on the "Check Orphan Apps" button, as shown in the image below.
![Check Orphan Apps action](https://docs.uptimize.merckgroup.com/assets/orphan-main-page.png)
* Once the user clicks on the Check Orphan Apps action, if any orphan apps are present for the user's use cases, the modal, will list all the orphan apps. The user can view the orphan apps along with the list of owners for each app, the use cases linked to the app, and the Transfer Ownership action.
![List Orphan apps](https://docs.uptimize.merckgroup.com/assets/orphan-apps-list.png)
* Next, click "Transfer Ownership" on the app details page. Once clicked, a confirmation prompt will appear. After confirmation, the ownership transfer process will begin.
![Confirm Transfer](https://docs.uptimize.merckgroup.com/assets/orphan-apps-transfer.png)
![Transfer Initiated message](https://docs.uptimize.merckgroup.com/assets/orphan-apps-transform-initiated.png)
* Once you close the Orphan Apps modal, you can view the orphan app being updated in the App Service Console. After the update is completed, you will receive owner permissions for the app.
![Ownership transfer completed](https://docs.uptimize.merckgroup.com/assets/orphan-app-transfer-done.png)

## Runtime Configuration

Users can set a runtime configuration using the App Service UI, for example to store secrets or other configuration options. This configuration will be exposed as environment variable `APP_SERVICE_CONFIG` to the app. Internally, the value of the configuration is stored in a secret in AWS Secrets Manager. If the runtime configuration is not used, the environment variable will not be present.

## Multiple Environments

Owners can grant apps the permission to push to other apps. This is useful for apps that should have multiple environments, for example `app1-dev` and `app1-prod`. 
An Owner of both apps can go to the configuration of `app1-dev` and allow `app1-prod` to push to the `app1-dev` ECR repository.
Once this is setup, the repository of `app1-dev` should not be used anymore and the pipeline of `app1-prod` can be adjusted to contain multiple stages:

* Building the Docker Image
* Pushing the Docker Image to `app1-dev`
* Manual Validation (Confirm Production Deployment)
* Pushing the Docker Image to `app1-prod` 

This is an example pipeline that can be copy & pasted into the `azure-pipelines.yml` of `app1-prod`. 

**Make sure to replace placeholders <ENTER_app1-dev_ID_HERE> and <ENTER_app1-prod_REPOSITORY_NAME_HERE> with real values in the yaml below.**
- **<ENTER_app1-dev_ID_HERE>: git repository name of `app1-dev` without the leading app name, e.g. app-szqavribsnsqcql4**
- **<ENTER_app1-prod_REPOSITORY_NAME_HERE>: full git respository name of `app1-prod`, e.g. app1-prod-app-lrxipp4qmtznvmc0**

```yaml
# App Service Multi-Environment Pipeline

trigger:
  branches:
    include:
    - '*' 
    - refs/tags/*

pool:
  vmImage: 'ubuntu-22.04'

variables:
  isMain: $[eq(variables['Build.SourceBranch'], 'refs/heads/main')]

resources:
  repositories:
    - repository: templates
      name: 'factory-appservice-nreg-ec1/factory-appservice-nreg-ec1' # <project>/<repo>  
      type: git
      ref: refs/heads/master

stages:
  - stage: BuildAndPushDev
    jobs:
      - job: CIAndDevDeployment
        steps:
          # Uncomment the following line in case you need to login to the private artifacts pypi repository
          # e.g. for consuming packages like BayBe
          # the template will expose env. variable PIP_EXTRA_INDEX_URL which can be used in the docker build
          #- template: pipeline-templates/artifacts-login.yml@templates          
          
          - template: pipeline-templates/aws-login.yml@templates # this template will expose APP_ID & APP_DESTINATION_ID as variable.
            parameters:
              AppDestinationId: '<ENTER_app1-dev_ID_HERE>'
          
          - template: pipeline-templates/docker-login.yml@templates # this template will expose AWS_ACCOUNT_ID as variable.
          
          - bash: |
              docker build \
                --pull \
                --cache-from $(AWS_ACCOUNT_ID).dkr.ecr.eu-central-1.amazonaws.com/$(APP_ID):main \
                -t $(AWS_ACCOUNT_ID).dkr.ecr.eu-central-1.amazonaws.com/$(APP_ID):main \
                -t docker-image:snapshot \
                .
            displayName: Build
            env:
              DOCKER_BUILDKIT: '1'
              BUILDKIT_PROGRESS: 'plain'
          
          - bash: |
              docker tag docker-image:snapshot $(AWS_ACCOUNT_ID).dkr.ecr.eu-central-1.amazonaws.com/$(APP_DESTINATION_ID):main
              docker push $(AWS_ACCOUNT_ID).dkr.ecr.eu-central-1.amazonaws.com/$(APP_DESTINATION_ID):main              
            displayName: PushContainer (main only)
            condition: and(succeeded(), eq(variables.isMain, 'true'))
            
          - bash: |
              docker image save docker-image:snapshot -o $(Build.ArtifactStagingDirectory)/docker-image.tar             
            displayName: SaveDockerTar
            condition: and(succeeded(), eq(variables.isMain, 'true'))
          
          - publish: $(Build.ArtifactStagingDirectory)
            artifact: docker-images
            displayName: SaveDockerToArtifacts
            condition: and(succeeded(), eq(variables.isMain, 'true'))

  - stage: WaitForValidation
    condition: and(succeeded(), eq(variables.isMain, true))
    jobs:    
      - job: waitForValidation
        displayName: Deploy to production?
        pool: server
        timeoutInMinutes: 4320 # job times out in 3 days
        steps:
        - task: ManualValidation@0
          timeoutInMinutes: 1440 # task times out in 1 day
          inputs:
            notifyUsers: |
              [factory-appservice-apps-p-nreg-ec1]\<ENTER_app1-prod_REPOSITORY_NAME_HERE>
            instructions: 'Please validate and confirm if you want to deploy to production'
            onTimeout: 'reject'

  - stage: PushProd
    condition: and(succeeded(), eq(variables.isMain, true))
    jobs:
      - job: ProdDeployment
        steps:
          - template: pipeline-templates/aws-login.yml@templates # this template will expose APP_ID & APP_DESTINATION_ID as variable.

          - template: pipeline-templates/docker-login.yml@templates # this template will expose AWS_ACCOUNT_ID as variable.
          
          - download: current
            artifact: docker-images
            displayName: LoadDockerFromArtifacts
          
          - bash: |
              docker load --input $(Pipeline.Workspace)/docker-images/docker-image.tar
            displayName: LoadDockerTar

          - bash: |
              docker tag docker-image:snapshot $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/$(APP_ID):main
              docker push $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/$(APP_ID):main
            displayName: PushContainer (main only)
            condition: and(succeeded(), eq(variables.isMain, 'true'))
```

This setup can also be used to deploy a template app to multiple other template deployments. This is useful for classrooms training where each participant should have one app but the initial app should be sourced from a central repository.

## Tips and Tricks

**Determining whether code runs on AppService:** 

Sometimes it is useful to have distinct behaviour depending on whether code runs on the AppService or in another environment.
Below is a utility function that can be used to determine whether the code is executed on the AppService.
```python
import os

def runs_on_app_service() -> bool:
    """Check if running on app service.

    Returns:
        bool: True if running on app service.
    """
    return "APP_SERVICE_TS" in os.environ
```
