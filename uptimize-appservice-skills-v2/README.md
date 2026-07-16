# UPTIMIZE App Service Plugin for Claude Code & OpenCode

A plugin that guides developers through deploying applications to UPTIMIZE App Service — from template selection to pipeline debugging.

## What it does

Two skills covering the full deployment flow:

### `/uptimize-deploy` — Setup → Clone → Code Guidance → Push

1. **Setup** — installs Azure CLI, ADO extension, WSL browser setup, SSO login
2. **Clone & Analyze** — parses your ADO repo URL, reads your cloned template, detects framework
3. **Code Guidance** — tells you exactly what to change (Dockerfile, environment.yml, src/ structure)
4. **Deploy** — confirms your changes, guides you to commit and push

### `/uptimize-debug` — Pipeline Monitoring → Log Reading → Diagnosis

1. **Monitor** — waits for pipeline, polls until complete
2. **Diagnose** — reads failed step logs, identifies one issue at a time
3. **Fix loop** — guides you to fix, push, and retry until succeeded
4. **ECS monitoring** — guides through post-pipeline deployment on AWS

**Supported templates:** Streamlit · Plotly Dash · R Shiny · FastAPI + React

## Prerequisites

- **Claude Code** or **OpenCode** installed and running
- **Git** — for cloning and pushing to ADO
- **Foundry Use Case** — you must be Owner, Product Owner, or Technical Owner of a use case in 'Proof of Value Development' or 'Industrialization' status

> Azure CLI, ADO extension, and SSO login are handled by the skill itself — no pre-installation needed.

## Installation

### Claude Code

From inside your project directory:

```bash
git clone <this-repo-url>
cd uptimize-appservice-skills
cp -r .claude ../
chmod +x ../.claude/hooks/validate-az.sh
cd ..
rm -rf uptimize-appservice-skills
```

### OpenCode

From inside your project directory:

```bash
git clone <this-repo-url>
cd uptimize-appservice-skills
cp -r .claude ../
cp -r .opencode ../
chmod +x ../.claude/hooks/validate-az.sh
cd ..
rm -rf uptimize-appservice-skills
```

Then open your project:

```bash
claude    # or opencode
```

Skills and hooks load automatically.

## MCP Setup (Recommended)

The **UPTIMIZE Docs MCP** enhances the skills with the latest platform documentation. The plugin includes local resource files that cover core docs, so it works without MCPs — but adding them gives you the most up-to-date guidance.

To find available MCPs and how to add them:
👉 [UPTIMIZE Integration Hub — Consume MCP Servers](https://docs.uptimize.merckgroup.com/agents/integration-hub/consumption/#consume-registered-mcp-servers%2C-a2a-agents-and-rest-tools)

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "UPTIMIZE Docs": {
      "type": "streamable-http",
      "url": "<uptimize-docs-mcp-url>",
      "headers": {
        "Authorization": "Bearer <your-api-token>"
      }
    }
  }
}
```

## How to use

### Claude Code

Type the slash command directly:

```
/uptimize-deploy     # Full deployment flow
/uptimize-debug      # Pipeline debugging (standalone or after deploy)
```

### OpenCode

The agent loads skills automatically based on context. Just ask:

```
"Deploy my app to App Service"        → loads uptimize-deploy
"My pipeline failed"                   → loads uptimize-debug
```

Or reference the skill explicitly — the agent discovers it from `.claude/skills/`.

Both agents walk you through each phase and wait for confirmation before moving forward.

## Safety Hook

The plugin includes safety hooks for both agents that intercept all `az` commands:

**Allowed (read-only diagnostics):**
- `az login`, `az account show`
- `az pipelines show/list/runs`
- `az devops invoke` (timeline, logs)
- `az devops configure`

**Blocked (write operations):**
- Any `az` command with `create`, `delete`, `update`, `remove`, `set`
- `az deployment`, `az role assignment`, `az webapp`, `az container`

This means even if your account has full permissions, the agent cannot accidentally run write operations.

| Agent | Hook file | Mechanism |
|-------|-----------|-----------|
| Claude Code | `.claude/hooks/validate-az.sh` | Bash script, registered as PreToolUse hook in `settings.json` |
| OpenCode | `.opencode/plugins/validate-az.ts` | TypeScript plugin, uses `tool.execute.before` hook, throws Error to block |

## Architecture

```
Code push (git push to main)
    → Azure DevOps Pipeline triggers
        → Checkout repo
        → Get AWS credentials (OIDC)
        → Login to AWS ECR
        → Docker build
        → Docker push to ECR (main branch only)
    → AWS ECS picks up new image and deploys automatically
```

Runtime logs are in AWS CloudWatch — accessible from the App Service console.

## Plugin structure

```
.claude/                                  # Shared + Claude Code specific
├── settings.json                         # Claude Code hook registration
├── hooks/
│   └── validate-az.sh                    # Claude Code safety hook (bash)
├── skills/                               # SHARED — both agents read this path
│   ├── uptimize-deploy/
│   │   └── SKILL.md                      # Setup → Clone → Code Guidance → Push
│   └── uptimize-debug/
│       ├── SKILL.md                      # Pipeline monitoring → Diagnosis → Fix loop
│       ├── known-issues.md               # Common pipeline errors + fixes
│       └── pipeline-commands.md          # Verified az command reference
└── resources/                            # SHARED — App Service platform docs
    ├── README.md                         # Index — which file covers what
    ├── 01-introduction.md                # What is App Service, security model, roles
    ├── 02-whats-new.md                   # Changelog
    ├── 03-best-practices.md              # Data access, quotas, runtime config, multi-env
    ├── 04-github-integration.md          # GitHub Actions, self-hosted runners
    ├── 05-factory-integration.md         # Factory accounts, STS, S3, Lambda
    ├── 06-third-party-apis.md            # NLP API, BayBE, SLURM
    ├── 07-special-settings.md            # Entra ID, egress, custom TPA
    └── 08-databases.md                   # DBaaS intro, usage, admin

.opencode/                                # OpenCode specific
└── plugins/
    └── validate-az.ts                    # OpenCode safety hook (TypeScript)
```

**Why `.claude/skills/` is shared:** OpenCode natively searches `.claude/skills/<name>/SKILL.md` for agent skills ([docs](https://opencode.ai/docs/skills/)). No duplication needed — both agents read the same skill files.

## Known Limitations

- **No CloudWatch log access via CLI** — runtime logs require the App Service console or AWS console
- **No container SSH** — not supported by the platform
- **`az repos clone` does not exist** — always use standard `git clone` with Generate Git Credentials from ADO
- **OpenCode plugin API** — the TypeScript hook follows the current OpenCode plugin spec; check for updates if the API changes

## Contributing

**Add a known pipeline issue:** Edit `.claude/skills/uptimize-debug/known-issues.md` — include error pattern (exact text from logs), cause, and fix.

**Update platform docs:** Edit the relevant file in `.claude/resources/`. See `resources/README.md` for the index.
