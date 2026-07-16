# Introduction to the UPTIMIZE App Service

## What is the UPTIMIZE App Service?

The [UPTIMIZE App Service](https://console.apps.p.uptimize.merckgroup.com/) provides a convenient and easy to use hosting service for container-based web applications. 
The target users of the App Service are technical data practitioners (e.g. data scientists, data engineers or software engineers) who want to share a data & analytics app with their Merck-wide audience in a secure and compliant way. The App Service is fully integrated into the UPTIMIZE governance and operating model as each app is tighly coupled to a use case and it's permission model maintained in Foundry. First-class support as well as example apps are currently provided for the following open source frameworks: 

* Streamlit
* Plotly Dash
* R Shiny
* FastAPI (Backend) + React (UI)

## Foundry Integration

The running apps have network connectivity as well as an OAuth2 Integration to Foundry - after the users logs in with Single-Sign-On (SSO) each request arriving at the App Service container port contains the Foundry Token of the logged in user. The developer can utilize the token to make requests for data or writeback data to Foundry on behalf of the end-user.

## Security Model

Apps are linked to Foundry use cases and the respective use case projects. Users can create apps for use cases where they have on of the following roles, as defined in the use case portal:

* Owner
* Product Owner
* Technical Owner

Users are logged into the app with Foundry SSO. The permissions of the user (Token Resources in the below picture) is the intersection of the users permissions and the app permissions.

![Permissions](https://docs.uptimize.merckgroup.com/assets/app-service-permissions.png)

In practice, this means that you can only access resources (e.g. datasets) - on behalf of the end-user - in the enabled use case projects. All other requests will fail.

Apps can communicate with a number of AWS resources (e.g. S3, Lambda) deployed in factory accounts through VPC Endpoints. IAM Trust Policies make sure principles of least-priviliges are followed.

### Developer roles

- **Owner:** Can update & change App configurations and settings as well as deleting the App. 
- **Contributor:** Can only access Azure DevOps, modify code and trigger pipelines.

Both roles can be assigned by the **Owner** of the App in the App Service UI.

## What distinguishes the App Service from other offerings in UPTIMIZE Foundry?

Foundry offers a wide range of solutions to share your analytical work:

* [Reports](https://palantir.mcloud.merckgroup.com/workspace/documentation/product/reports/overview#reports)
  * Create documents and dashboards to share your analytical work

* [Slate](https://palantir.mcloud.merckgroup.com/workspace/documentation/product/slate/overview)
  * Build interactive visualizations and dashboards
* [Workshop](https://palantir.mcloud.merckgroup.com/workspace/documentation/product/workshop/overview)
  * Build interactive applications for operational users

The UPTIMIZE ecosystem also includes Tableau as visual storytelling and dashboarding tool.

![Information](https://docs.uptimize.merckgroup.com/assets/app-service-comparison.png)

The App Service is an additional offering that allows for very flexible deployment of end-user facing apps - mainly for hosting popular open source frameworks.