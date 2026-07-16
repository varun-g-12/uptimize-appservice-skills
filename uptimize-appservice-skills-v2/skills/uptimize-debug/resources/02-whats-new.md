# What's New

## 08.04.2026

* [oneHPC (SLURM) Integration](/appservice/third-party-apis/#onehpc---slurm) -- Apps can now connect to the oneHPC high-performance computing cluster via the SLURM REST API. Enable the toggle in the External APIs section to get started.

## 12.12.2024

* Support for creating an OIDC trust relationship to GitHub repositories in the merckgroup organization

## 08.11.2023

* Configuration updates do not require the app to be in a running state anymore
* Inject additional headers with more user information (requires app update)
  * `X-Appservice-Firstname`
  * `X-Appservice-Lastname`
  * `X-Appservice-Muid`
  * `X-Appservice-Email`
* Add App analytics
  * Display anonymous user activity (daily/monthly active users)
* Snowflake integration
  * Select if you want to create a Snowflake or a Foundry app
* Streamlit app template update
  * integrate new features in the template (snowflake, additional userinfo from headers)
* [BayBe API](https://docs.uptimize.merckgroup.com/appservice/third-party-apis/#BayBe) integration 
* Enhanced [Foundry Security Settings](https://docs.uptimize.merckgroup.com/appservice/special-settings/)

## 15.08.2023

* Configure ephemeral storage size for ECS deployment in the management console.

## 21.06.2023

* Deploying an app to [multiple environments](https://docs.uptimize.merckgroup.com/appservice/best-practices-app-service/#multiple-environments) is supported now.

## 15.05.2023

* GPT API Samples added to streamlit example app.

## 02.02.2023

* NLP API Prod Integration is live.

## 03.01.2023

* NLP API Integration is live.

## 23.12.2022

* App state is now read from DynamoDB. You should not see throttling exceptions anymore when many people visit the app service at the same time.
* NLP API Integration is deployed in Preview mode.

## 09.12.2022

* Added the feature to add a runtime configuration to the app. Users can pass configuration to the app from the UI. This configuration will be exposed as environment variable `APP_SERVICE_CONFIG`.