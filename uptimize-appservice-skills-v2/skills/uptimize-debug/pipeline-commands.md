# ADO CLI Pipeline Commands Reference

All commands verified and tested. Always use `--query` and `--output table` to minimize token usage.

## Concepts

| Term | What it is | Lifetime |
|------|-----------|----------|
| **Pipeline ID** | Identifies your pipeline definition | Permanent (stays same forever) |
| **Run ID** | Identifies a specific build execution | New one each push |
| **Log ID** | Identifies logs for a specific step within a run | Tied to the run |

## Commands

### Find Pipeline ID (one-time)

```bash
az pipelines show --name "<repo-name>" --query "id"
```

Returns a number. The pipeline name matches the repo name.

**Never run `az pipelines list` without `--name` or `--top`** — the project has 10k+ pipelines.

### Get Latest Run

```bash
az pipelines runs list --pipeline-id <pipeline-id> --top 1 \
  --query "[].{runId:id, status:status, result:result, commit:triggerInfo.\"ci.message\"}" \
  --output table
```

### Check Run Status

```bash
az pipelines runs show --id <run-id> \
  --query "{status:status, result:result, startTime:startTime, finishTime:finishTime}"
```

### List All Steps with Log IDs

```bash
az devops invoke \
  --area build \
  --resource timeline \
  --route-parameters project=<project> buildId=<run-id> \
  --org <org-url> \
  --query "records[?type=='Task'].{order:order, name:name, result:result, logId:log.id}" \
  --output table
```

**Note:** The step `order` is NOT the same as `logId`. Always use this command to map them.

### Read Logs for a Specific Step

```bash
az devops invoke \
  --area build \
  --resource logs \
  --route-parameters project=<project> buildId=<run-id> logId=<log-id> \
  --org <org-url> \
  --query "value[]" -o tsv
```

Add `| tail -40` for large steps (Docker Build can be 900+ lines).
Add `| head -40` to see the beginning of the step.

### Trigger a Pipeline Manually

```bash
az pipelines run --id <pipeline-id> --branch main
```

## Typical Pipeline Steps

| Order | Step Name | What it does |
|-------|-----------|-------------|
| 1 | Initialize job | Sets up build agent |
| 2 | Checkout | Clones the repo |
| 3 | Get AWS Push Credentials | Gets OIDC-based AWS creds |
| 4 | ECR Login | Authenticates with AWS ECR |
| 5 | Build | Builds Docker image |
| 6 | Push (main only) | Pushes image to ECR (skipped on non-main) |
| 7 | Post-job: Checkout | Cleanup |
| 8 | Finalize Job | Final cleanup |

## Placeholders

Replace these in all commands:
- `<project>` → your ADO project name (e.g., `factory-appservice-apps-p-nreg-ec1`)
- `<org-url>` → `https://dev.azure.com/<org-name>` (e.g., `https://dev.azure.com/Uptimize`)
- `<pipeline-id>` → number from `az pipelines show`
- `<run-id>` → number from `az pipelines runs list`
- `<log-id>` → number from timeline query
