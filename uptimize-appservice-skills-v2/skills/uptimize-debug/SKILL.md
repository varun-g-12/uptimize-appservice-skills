---
name: uptimize-debug
description: Debug and monitor UPTIMIZE App Service pipelines. Reads pipeline logs, identifies failures, and guides fixes one issue at a time. Works standalone or after /uptimize-deploy.
when_to_use: User says "pipeline failed", "debug pipeline", "check my pipeline", "deployment error", "build failed", "monitor pipeline", or user just pushed and wants to check status.
allowed-tools: Bash(az *) Bash(pip *) Bash(find *) Bash(ls *) Bash(sleep *)
---

## Instructions

You are helping a developer debug their UPTIMIZE App Service pipeline.
**Tell the user what you are doing before every command.**

Read both reference files before doing anything else:
- `known-issues.md` — known error patterns and fixes
- `pipeline-commands.md` — verified az commands, warnings, and pipeline step reference

Use these files as your source of truth throughout this skill.

## Resource Files

When diagnosing issues that need platform documentation, read from `resources/`:

| Topic | File |
|-------|------|
| Data access, runtime config, quotas | `03-best-practices.md` |
| AWS services (S3, Lambda) | `05-factory-integration.md` |
| NLP API, BayBE API, SLURM | `06-third-party-apis.md` |
| Internet access, Entra ID, special settings | `07-special-settings.md` |
| Databases, PostgreSQL, DBaaS | `08-databases.md` |

---

## Step 1: Get repo details

If the user came from `/uptimize-deploy`, you may already know org, project, and repo. If not, ask:

"To debug your pipeline, I need your ADO repo URL. It looks like:
`https://dev.azure.com/<org>/<project>/_git/<repo-name>`

You can find it in the App Service console → click the **ADO repo symbol** on your app.

Paste the URL here."

Parse the URL:
- `org` = segment after `dev.azure.com/`
- `project` = next segment
- `repo` = segment after `_git/`

Tell the user: "Parsed — org: `<org>`, project: `<project>`, repo: `<repo>`"

---

## Step 2: Setup ADO CLI defaults

Tell the user: "Setting up ADO CLI defaults using your repo details."

```bash
az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>
```

---

## Step 3: Get pipeline ID

Tell the user: "Looking up your pipeline ID."

Run `az pipelines show` using the repo name. Refer to `pipeline-commands.md` for the exact command.

---

## Step 4: Wait and check

Tell the user: "Waiting 60 seconds for the pipeline to pick up your push before checking run status..."

Run `sleep 60` as a standalone Bash command (not combined with az), then:

Tell the user: "Checking latest pipeline run."

Run `az pipelines runs list` for the pipeline ID. Refer to `pipeline-commands.md` for the exact command.

---

## Step 5: Evaluate result

### `status: inProgress`

Tell the user: "Pipeline is still running. Docker builds typically take 2-3 minutes. I'll check again shortly."

Wait 30 seconds (`sleep 30`), re-run the runs list command. Repeat until status is `completed`.

### `result: succeeded`

Tell the user: "Pipeline succeeded! Your Docker image has been built and pushed to ECR.

**What happens next — monitor your deployment:**
1. Go to the **App Service console** → find your app in the list
2. Wait ~4-5 minutes — after that the status will turn grey **'In Progress'** as AWS ECS picks up the new image and starts the container
3. Wait for it to turn green **'Update Complete'**
4. Once green, click the **app URL** to open your app

**To watch live logs while it deploys:**
- In the console → your app → click **Logs** → this opens CloudWatch live tail
- You'll see the container starting up in real time

Let me know once the status turns green or if you see any errors in the logs."

### `result: failed`

Tell the user: "Pipeline failed. Let me find which step failed."

Run the timeline command to list steps and log IDs. Refer to `pipeline-commands.md` for the exact command. The pipeline step table in that file shows what each step does — use it to understand which step failed.

Tell the user: "Step '[name]' failed (logId: [id]). Reading the logs."

Run the logs command for that logId. Refer to `pipeline-commands.md` for the exact command and tail/head guidance for large log outputs.

---

## Step 6: Diagnose — ONE issue at a time

1. Read the error from the logs
2. Check `known-issues.md` for a matching error pattern
3. If not found → read the relevant resource file from `resources/`
4. If not found → check App Service Issues MCP (if available)
5. If not found → check UPTIMIZE Docs MCP (if available)
6. If still unknown → use Claude's knowledge

Tell the user: "Here is the issue I found: [description]. Here is how to fix it: [fix]."

**Important:** Identify and explain ONE issue only. Do not list multiple problems at once.

Wait for user to fix → commit → push → go back to Step 4 (wait and check).

Repeat until `result: succeeded`.
