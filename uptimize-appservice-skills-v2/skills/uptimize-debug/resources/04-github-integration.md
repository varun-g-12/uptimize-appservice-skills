# GitHub Integration
To integrate GitHub with the UPTIMIZE App Service, you can use GitHub Actions to automate your workflows. Below are examples of how to set up GitHub Action Pipelines in a merckgroup repository to ...
- build a Docker image and push it to Elastic Container Repository (ECR) where an automated process will deploy it to the UPTIMIZE App Service.
- update the Runtime Configuration of an App Service app from secrets stored in GitHub Secrets.

You will need to add the name of your repository to the app settings in the Console before the token exchange for AWS Credentials will work.

See this repository for reusable template GitHub workflows: [merckgroup/appservice-workflows](https://github.com/merckgroup/appservice-workflows)

### Docker Build and Push to App Service
See the following diagram for a high level overview of the authentication process achieved by the configuration below:
![OIDC Authentication Process](assets/appservice/appservice-github-oidc-process.png)

```yaml
name: Deploy to App Service

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy-appservice:
    uses: merckgroup/appservice-workflows/.github/workflows/deploy_appservice.yml@main
    with:
        # set these variables in your repository settings
        # See: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables#creating-configuration-variables-for-a-repository 
        app-id: {% raw %}${{ vars.APPSERVICE_APP_ID }}{% endraw %}  # example: 'app-tbzjap3ulr3gvxtz'
        app-name: {% raw %}${{ vars.APPSERVICE_APP_NAME }}{% endraw %}  # example: 'my-app'
```

### Update Runtime Configuration from GitHub Secrets

The following example **overrides** your App Service App's Runtime Configuration with secrets stored in a GitHub repoisitory's secrets store. You can **either** hand-pick specific secrets to update **or** dump all secrets into the Runtime Configuration. This approach replicates the behavior of the App Service UI where you can also enter secrets as JSON and expose them into your apps environment via the `APP_SERVICE_CONFIG` environment variable.
See the [Runtime Configuration Section](#runtime-configuration).

**Note**: The base64 step is necessary, as GitHub currently does not allow propagating secrets into another step or job. In order to use our template, we bypass this via Base64 encoding twice. See this [GitHub Discussion](https://github.com/orgs/community/discussions/25225#discussioncomment-6776295) for more details.

#### Option 1: Hand-pick the secrets you want to update

```yaml
name: Update MyApp Runtime Configuration

on:
  workflow_dispatch:

jobs:
  build-secrets:
    runs-on: ubuntu-latest
    outputs:
      secrets_json: {% raw %}${{ steps.build-json.outputs.secrets_json }}{% endraw %}
    steps:
      - name: Build and encode secrets JSON
        id: build-json
        env:
          API_KEY_FOUNDRY: {% raw %}${{ secrets.API_KEY_FOUNDRY }}{% endraw %}
          API_KEY_NLP: {% raw %}${{ secrets.API_KEY_NLP }}{% endraw %}
        run: |
          SECRETS_JSON=$(jq -nc \
            '{
              "API_KEY_FOUNDRY": env.API_KEY_FOUNDRY,
              "API_KEY_NLP": env.API_KEY_NLP
            }')
          echo "secrets_json=$(echo "$SECRETS_JSON" | base64 -w0 | base64 -w0)" >> $GITHUB_OUTPUT

  call-update-secrets:
    needs: build-secrets
    uses: merckgroup/appservice-workflows/.github/workflows/update_secrets.yml@main
    with:
      app-id: {% raw %}${{ vars.APPSERVICE_APP_ID }}{% endraw %}  # example: 'app-tbzjap3ulr3gvxtz'
      app-name: {% raw %}${{ vars.APPSERVICE_APP_NAME }}{% endraw %}  # example: 'my-app'
    secrets:
      secrets_json_encoded: {% raw %}${{ needs.build-secrets.outputs.secrets_json }}{% endraw %}
```

#### Option 2: Push all secrets from the repository's secrets store

```yaml
name: Update MyApp Runtime Configuration

on:
  workflow_dispatch:

jobs:
  build-secrets:
    runs-on: ubuntu-latest
    outputs:
      secrets_json: {% raw %}${{ steps.build-json.outputs.secrets_json }}{% endraw %}
    steps:
      - name: Build and encode secrets JSON
        id: build-json
        env:
          SECRETS_JSON: {% raw %}${{ toJson(secrets) }}{% endraw %}  # dump all repo secrets into a json string
        run: |
          echo "secrets_json=$(echo "$SECRETS_JSON" | base64 -w0 | base64 -w0)" >> $GITHUB_OUTPUT

  call-update-secrets:
    needs: build-secrets
    uses: merckgroup/appservice-workflows/.github/workflows/update_secrets.yml@main
    with:
      app-id: {% raw %}${{ vars.APPSERVICE_APP_ID }}{% endraw %}  # example: 'app-tbzjap3ulr3gvxtz'
      app-name: {% raw %}${{ vars.APPSERVICE_APP_NAME }}{% endraw %}  # example: 'my-app'
    secrets:
      secrets_json_encoded: {% raw %}${{ needs.build-secrets.outputs.secrets_json }}{% endraw %}
```

## Self-Hosted GitHub Actions Runners for Internal API Access

#### Overview

> **⚠️ Advanced Feature**: This is an advanced integration requiring GitHub Enterprise licensing and technical expertise. For basic GitHub integration with AppService, see the [AppService GitHub Integration](#github-integration) section first.

#### Demo
[See here](https://mdigital.sharepoint.com/:v:/s/UPTIMIZEAWSAPP_Services/EY-aY-xPPkVLljahcZ0AIhQBC20_e1rScxSpqQD_AGAknA?e=kX3WsC) for an introduction and demonstration.

#### Problem & Use Cases

Standard GitHub- or Azure-hosted runners cannot access internal Merck networks, limiting automation capabilities for:

- **Integration testing** of applications that consume Foundry data, UPTIMIZE AI-ML Services or MyGPT APIs
- **End-to-end testing** of AppService applications before deployment

##### Compute Options
- **XS**: 2 vCPU, 4GB RAM - for lightweight testing
- **S**: 4 vCPU, 8GB RAM - for standard workloads
- **M**: 4 vCPU, 16GB RAM - for memory-intensive tasks

#### User Workflow

![User Workflow Diagram](assets/appservice/appservice-github-selfhosted-runners-process.png)

##### 1. Request Access
Submit an access request through the [GitHub repository](https://github.com/merckgroup/selfhosted-aws-runners/issues/new?template=access-request.yml) with your **UPTIMIZE Use Case ID**.

##### 2. Add to Your Workflow
Include the runner in your existing GitHub Actions workflow [see here for a basic GitHub Actions documentation](https://docs.github.com/en/actions/get-started/quickstart):

```yaml
jobs:
  add-runner:
    uses: merckgroup/selfhosted-aws-runners/.github/workflows/runner_attach_workflow.yml@main
    with:
      RunnerComputeType: "XS"  # (OPTIONAL)
      RunnerArchitecture: "x64" # (OPTIONAL) one of ["arm64", "x64"]
      UseCaseID: "your-use-case-id"  # (REQUIRED)

  your-tests:
    needs: add-runner
    runs-on: {% raw %}${{ needs.add-runner.outputs.runner_id }}{% endraw %}
    steps:
      - name: Run integration tests
        run: python test_foundry_integration.py
```

##### 3. Access Internal APIs
Your workflow can now securely access:
- Foundry datasets and APIs
- UPTIMIZE AI-ML Services (Qdrant, Langfuse, LLMs, MLFlow, etc.)
- Langfuse
- Qdrant
- MyGPT APIs

#### Prerequisites

- **Access to the GitHub merckgroup organistaion** (you must be a member of the organization)
- **UPTIMIZE Use Case ID** for access approval. This is solely used for cost tracking and auditing.
- **Basic GitHub Actions knowledge** - familiarity with workflows and CI/CD concepts
- **Internal API credentials** (Foundry tokens, AI-ML Services keys, MyGPT API keys, etc.)

#### How It Works

The solution provides **just-in-time** self-hosted runners that:

1. **Spin up on-demand** when your GitHub workflow needs them
2. **Connect to internal networks** with proper security and access controls
3. **Execute your tests/jobs** with access to Foundry, UPTIMIZE AI-ML Services, MyGPT APIs, and other internal services
4. **Auto-terminate** after job completion (typically within 15 seconds to 5 minutes)

#### Resources

- **Complete documentation**: [GitHub Repository](https://github.com/merckgroup/selfhosted-aws-runners)
- **Working examples**: See the `workflows/EXAMPLE_user_workflow.yml` in the repository
- **Technical setup**: Full Terraform infrastructure and configuration details in the repo README

#### When NOT to Use Self-Hosted Runners

**Don't use self-hosted runners for workloads that don't require internal API access.** Please stick to the default GitHub-hosted runners for:

- Standard unit tests that don't access internal APIs
- Code quality checks (linting, formatting)
- General CI/CD tasks that only use external/public services

For a concrete example of appropriate vs. inappropriate use cases, visit the working example referenced above.

#### Support & Limitations

- Runners auto-terminate after inactivity (no more GitHub jobs running)
- Designed for integration testing, not production workloads
- For feature requests or issues, please open a new issue in the [GitHub repository](https://github.com/merckgroup/selfhosted-aws-runners/issues)

#### FAQ

- **Q: Why do I receive timeouts when trying to reach UPTIMIZE Qdrant?**
  - A: Similar to the usage of Qdrant in Foundry or AppService, you need to use port 443 instead of 6333 to access Qdrant, and add the prefix "uptimize_nlp" to the QdrantClient, as described in the Vector Database documentation of the AI-ML Services. For conditional logic that correctly handles the different environments, you can use the `runs_on_app_service()` utility function provided above and extend it with a check for whether the code is running on a GitHub CI pipeline:
```python
def is_running_in_ci() -> bool:
  """Check if the code is running in a CI environment."""
  return os.getenv("GITHUB_ACTIONS", "false").lower() == "true"
```

- **Q: Can the runner only access the Foundry Use Case whose ID I provide in the request?**
  - A: No, the Use Case ID is just used for allowlisting and for cost tracking. It is not used for any scoped access to Foundry. For this, you need to bring your own Foundry Credentials/Tokens as secrets to the GitHub repository and connect via those.