# Third Party APIs

## Introduction and intended use

We are integrating external APIs into the App Service. When deploying or updating an App, you can select which APIs you want to integrate into the App Service.
Therefore we inject headers into the requests to the container to connect to those APIs. We also make sure to create the correct network configuration to make sure 
those endpoints can be reached.

## NLP

Can can either connect to the `dev` or the `prod` NLP API. If enabled, we inject the header `APP_SERVICE_NLP_API_KEY` which can 
be used to connect to the API. Besides access to LLMs, this also offers the possibility to request an instance of the Qdrant Vector
Database. Please checkout the [NLP API](/aiml/) documentation for further information.

## BayBE

If enabled, we inject the headers `APP_SERVICE_BAYBE_API_URL` and `APP_SERVICE_BAYBE_API_KEY` which can be used to connect to the API.
Please checkout the [BayBE API](/baybe/) documentation for further information.

## oneHPC - SLURM

If enabled, we inject the following environment variables into your container:

| Variable | Description |
|----------|-------------|
| `APP_SERVICE_ONEHPC_API_URL` | Base URL for the standard Slurm REST API (`https://public-slurm-api.onehpc.merckgroup.com`). Requires a manually generated Slurm JWT. |
| `APP_SERVICE_ONEHPC_FOUNDRY_PROXY_URL` | Base URL for the oneHPC Foundry Slurm proxy (`https://slurm-proxy.onehpc.p.uptimize.merckgroup.com/v1`). Uses the logged-in user's Foundry identity -- no manual JWT required. |

Your app can submit batch jobs, monitor their status, and retrieve job results from the oneHPC HPC cluster.

### Prerequisites

You need an active oneHPC account with SSH access. For account setup, access requests, and SSH configuration, refer to the [oneHPC First Steps guide](https://onehpc-docs.apps.p.uptimize.merckgroup.com/docs/user/01_first-steps).

### How to Enable

1. When creating or updating your app, check **Enable access to external APIs**
2. Click the **oneHPC (SLURM)** label (it turns green when active)
3. Submit or update -- a CloudFormation update will configure network access and inject both environment variables

> **Note:** This can be combined with other toggles (BayBe, Snowflake, etc.) in the same update.

### Authentication

There are two supported authentication paths. Both are injected automatically -- choose based on your use case.
Please check out the [oneHPC SLURM API Reference](https://onehpc-docs.apps.p.uptimize.merckgroup.com/docs/developer/slurm) for details and/or check the example apps and templates deployed in App Service apps.

Store your JWT in the **Runtime Configuration** via the App Service console:

```json
{
  "SLURM_JWT": "<your-token-here>"
}
```

Generate a token on the cluster: `ssh <muid>@onehpc.merckgroup.com` → `scontrol token lifespan=3600`. See the [oneHPC SLURM docs](https://onehpc-docs.apps.p.uptimize.merckgroup.com/docs/developer/slurm) for details. Tokens expire after the specified lifespan -- regenerate when needed.

For service accounts, generate the token as the service account user and set `X-SLURM-USER-NAME` to the service account name (e.g. `svc-s123456`).

### Known Limitations

The SLURM API currently supports job submission and status monitoring only. Job output files cannot be retrieved directly from the cluster -- have your job script write results to **S3** or **Foundry**, then read them back in your app.

### Starter Templates

All starter templates (Streamlit, Dash, FastAPI + React, R Shiny, Next.js) include a working oneHPC integration with a **Bring Your Own JWT** option for quick testing without updating the Runtime Configuration.

For Streamlit apps, the template also demonstrates the **Foundry Proxy** path using Foundry Dev Tools. When running on App Service, no manual credential configuration is needed -- your Foundry identity is picked up automatically.

### Troubleshooting

| Problem | Solution |
|---------|----------|
| `APP_SERVICE_ONEHPC_API_URL` not set | Ensure the oneHPC toggle is enabled and the CloudFormation update has completed |
| `APP_SERVICE_ONEHPC_FOUNDRY_PROXY_URL` not set | Ensure the oneHPC toggle is enabled and the CloudFormation update has completed |
| 401 Unauthorized (Direct JWT) | JWT token expired -- regenerate via `scontrol token` and update the Runtime Configuration |
| 401 Unauthorized (Foundry proxy) | Foundry token is missing or expired. Verify that Foundry Dev Tools can read the token in your runtime. |
| 403 Forbidden (Foundry proxy) | The logged-in user's MUID is not onboarded to the target oneHPC project. Every user who triggers a Slurm request via the proxy must have active oneHPC project access. If this is a blocker, switch to the Direct Slurm JWT path with a service account. |
| 403 Forbidden (Direct JWT) | Your oneHPC account or service account may lack partition or project access -- contact the oneHPC team |
| Connection timeout | Confirm the **oneHPC (SLURM)** label is selected, not just the "Enable access to external APIs" checkbox |
| Token decoding error | Regenerate the token, ensure no extra whitespace or line breaks |
| Cannot retrieve job output | Write results to S3 or Foundry from your job script -- direct file retrieval from the cluster is not yet supported |

For full SLURM REST API documentation, refer to the [oneHPC SLURM API Reference](https://onehpc-docs.apps.p.uptimize.merckgroup.com/docs/developer/slurm).