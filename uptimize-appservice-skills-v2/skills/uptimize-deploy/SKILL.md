---
name: uptimize-deploy
description: Deploy applications on UPTIMIZE App Service. Guides through Azure CLI setup, SSO login, repo cloning, template analysis, code guidance, and pushing to ADO. Use for any App Service deployment task.
when_to_use: User says "deploy my app", "how do I use App Service", "set up UPTIMIZE", "what template should I use", "how do I push", or is new to UPTIMIZE App Service.
allowed-tools: Bash(az *) Bash(pip *) Bash(git status) Bash(git log *) Bash(git diff *) Bash(find *) Bash(ls *)
---

## Instructions

You are guiding a developer through deploying an app on UPTIMIZE App Service.
Work through the 4 phases in order. Confirm with the user before moving to the next phase.
**Tell the user what you are doing before every command.**

## Resource Files

When the user asks about a topic, read the relevant resource file from `resources/`:

| Topic | File |
|-------|------|
| What is App Service, permissions, roles | `01-introduction.md` |
| Recent features, changelog | `02-whats-new.md` |
| Data access, runtime config, quotas, multi-env | `03-best-practices.md` |
| GitHub Actions, self-hosted runners | `04-github-integration.md` |
| AWS services (S3, Lambda, DynamoDB) | `05-factory-integration.md` |
| NLP API, BayBE API, SLURM | `06-third-party-apis.md` |
| Internet access, Entra ID, custom auth | `07-special-settings.md` |
| Databases, PostgreSQL, DBaaS | `08-databases.md` |

Read `resources/README.md` if unsure which file to check. Only read a resource file when the user asks about that specific topic — do not read all resources upfront.

## MCPs (Optional)

These MCPs can supplement local resources when you cannot find the answer locally:
- **UPTIMIZE Docs MCP** — latest platform docs (use only if local resources don't cover the question)
- **App Service Wiki MCP** — community troubleshooting knowledge base (coming soon)

Do NOT call MCPs by default. Use local resource files first. Only fall back to MCPs when the user's question is not covered by any resource file.

---

## Phase 1: Setup

Tell the user: "Checking your setup."

### 0. Check safety hook

This plugin ships two safety hooks that block dangerous az write/delete commands:
- `.claude/hooks/validate-az.sh` — Claude Code (bash, needs execute permission)
- `.opencode/plugins/validate-az.ts` — OpenCode (TypeScript, auto-loaded by runtime)

Only the bash hook can fail silently due to missing permissions. Check it:
```bash
ls -la .claude/hooks/validate-az.sh 2>/dev/null
```

**If the file exists but is NOT executable (missing `x` in permissions):**
Tell the user: "The safety hook needs execute permission. Run this yourself:
```
chmod +x .claude/hooks/validate-az.sh
```
Let me know when done."
Wait for user to confirm. Re-check to verify. **Do not proceed until fixed.**

**If executable or file not found:** continue to step 1.

### 1. Check Azure CLI
```bash
az --version 2>/dev/null | head -1
```

**If not installed:**
Tell the user: "Azure CLI is not installed. Please run this yourself:
```
pip install azure-cli
```
Let me know when done."
Wait for user to confirm. Then re-run `az --version` to verify. Do not proceed until Azure CLI is confirmed installed.

**If installed:** continue to step 2.

### 2. Check ADO Extension
Only run this after Azure CLI is confirmed installed.
```bash
az extension show --name azure-devops --query version -o tsv 2>/dev/null
```

**If not installed:** Tell the user: "Installing the Azure DevOps extension." Then run:
```bash
az extension add --name azure-devops
```

**If installed:** continue to step 3.

### 3. WSL Browser Setup (WSL only)
Only run this after Azure CLI and ADO extension are confirmed.

Check if running in WSL:
```bash
uname -r 2>/dev/null | grep -qi microsoft && echo "WSL" || echo "not WSL"
```

**If WSL:** Check if `wslview` is installed:
```bash
which wslview 2>/dev/null
```

**If `wslview` not found:** Tell the user: "You're on WSL and need `wslu` installed so Azure login can open your Windows browser. Run this yourself:
```
sudo apt install wslu
```
Then restart your shell and come back."
Wait for user to confirm. Then re-check `which wslview` to verify.

**If `wslview` found or not WSL:** continue to step 4.

### 4. SSO Login
Only run this after Azure CLI, ADO extension, and WSL browser setup (if applicable) are confirmed.
```bash
az account show --query user.name -o tsv 2>/dev/null
```

**If not logged in:**
Tell the user: "Please log in with your Merck SSO account. Run this yourself (it opens a browser):
```
az login --allow-no-subscriptions
```
Let me know when done."
Wait for user to confirm. Then re-run `az account show` to verify. Do not proceed until login is confirmed.

**If logged in:** Tell the user: "Logged in as [name]. Setup complete."

---

## Phase 2: Create App & Clone Template

### Step 1: Choose app type

Ask the user: "What type of application are you building?"
- **Streamlit** — data apps and dashboards in Python
- **Plotly Dash** — interactive Python dashboards
- **R Shiny** — R-based interactive apps
- **FastAPI + React** — Python backend with React frontend

### Step 2: Prerequisites for creating an app

Tell the user: "Before creating the app, make sure you have:
- A **Foundry Use Case** where you are **Owner, Product Owner, or Technical Owner**
- The use case must be in **'Proof of Value Development'** or **'Industrialization'** status in Foundry
- At least one project created under that use case

If you don't have a use case yet, ask your team's use case owner to add you as an additional owner in the App Service."

### Step 3: Create the app in the console

Tell the user: "Go to **[console.apps.p.uptimize.merckgroup.com](https://console.apps.p.uptimize.merckgroup.com/)** and follow these steps:

1. Click the **Launch** button
2. Fill in the **Create Container App** form:
   - **App Name** — your app's name
   - **Container Port** — leave as `8080`
   - **Configuration** — compute size (default 0.25 vCPU, 512 MB is fine to start)
   - **App template** — select **[framework from Step 1]**
   - **Use Case** — select your Foundry use case
   - **Additional owners / contributors** — add team members if needed
3. Click **Launch**

The platform creates your ADO repo and pipeline automatically. Let me know once the app is created."

Wait for user to confirm.

### Step 4: Get repo URL and clone

Tell the user: "To get your ADO repo URL:
1. In the console, find your app in the list
2. Click the **ADO repo symbol** on your app — it opens the Azure DevOps repository
3. Copy the URL from your browser address bar. It looks like:
   `https://dev.azure.com/<org>/<project>/_git/<repo-name>`

Paste the URL here."

Once the user provides the URL, parse it:
- Extract `org` = segment after `dev.azure.com/`
- Extract `project` = next segment
- Extract `repo` = segment after `_git/`

Tell the user: "Parsed — org: `<org>`, project: `<project>`, repo: `<repo>`

Now clone it. In the ADO repo page → **Clone** → **Generate Git Credentials**, then run:
```
git clone <url>
cd <repo>
```
Let me know when cloned."

Wait for user to confirm. Then read the actual template files:
```bash
find . -maxdepth 3 -type f | sort
```
Read `Dockerfile` and `environment.yml` — confirm what's already in the template and detect framework from CMD.

---

## Phase 3: Code Guidance

Tell the user: "I've read your template. Here's exactly what you need to change to get your application working on App Service."

### Step 1: Understand the constraints (tell user all of these)

"Before making changes, here are the platform rules you must follow:

1. **Port 8080 is mandatory** — your app must listen on port 8080. The platform routes traffic to this port only.
2. **No internet at runtime** — the container has no internet access when running. All packages must be installed in the Dockerfile at build time via conda/pip. You cannot download models, data, or packages at startup.
3. **DO NOT modify `azure-pipelines.yml`** — it is fully managed by the platform. Any changes will break your pipeline.
4. **Foundry data access** — the Foundry token is injected into every request as the HTTP header `x-foundry-accesstoken`. Use the `foundry-dev-tools` library — it extracts the token automatically. Do NOT hardcode credentials.
5. **Runtime secrets/config** — do not put secrets in your code. Use the App Service console UI to set runtime config (stored in AWS Secrets Manager). Your app accesses it via the `APP_SERVICE_CONFIG` environment variable.
6. **User identity headers** — the platform injects these headers on every request:
   - `X-Appservice-Firstname`, `X-Appservice-Lastname`, `X-Appservice-Muid`, `X-Appservice-Email`"

### Step 2: Analyse the cloned template and guide changes

Read the actual files from the cloned repo:

```bash
find . -maxdepth 3 -type f | sort
cat Dockerfile
cat environment.yml
```

Also check:
```bash
ls config-template.json 2>/dev/null && echo "exists" || echo "not found"
ls .gitignore 2>/dev/null && echo "exists" || echo "not found"
```

**Detect framework from the Dockerfile CMD line:**
- `streamlit run` → Streamlit
- `python <file>.py` → Plotly Dash
- `shiny::runApp` → R Shiny
- `uvicorn` → FastAPI + React

Tell the user: "Your template is for **[framework]**. The Dockerfile expects your entry point at `src/[filename from CMD]`. Here is what you need to change:"

---

**`src/` — replace template files with your app**

List what's currently in `src/` so the user can see the template example files. Tell them:
- Delete all template example files (name them explicitly from the listing)
- Add your own app files — your main file must be named exactly `[filename from CMD]`

---

**`environment.yml` — add your dependencies**

Show the packages already listed. Tell them:
- Add your packages under `dependencies:` — keep channels (`conda-forge` + `nodefaults`) and Python version unchanged
- Use conda-forge package names (check https://anaconda.org/conda-forge if unsure)
- For pip-only packages, add a `pip:` subsection under `dependencies:`

---

**`Dockerfile` — usually no changes needed**

Tell them: "Do not change the base image, ENV variables, EXPOSE, or build steps. The only line you may need to update is the CMD entry point filename — and only if your main file has a different name than what the template uses."

**Exception — Plotly Dash and FastAPI only:**

For these two frameworks the port must also be set in the app code itself (the Dockerfile CMD passes port to the server, but the app must also bind to it):
- **Dash:** `app.run(host='0.0.0.0', port=8080, debug=False)` in `src/app.py`
- **FastAPI:** port is handled by uvicorn in the CMD — no change needed in `main.py`, but the FastAPI app must not hardcode a different port

For Streamlit and R Shiny, port is fully handled by the Dockerfile ENV/CMD — no app code change needed.

Read `resources/03-best-practices.md` for additional guidance on data access, runtime config, and technical limitations if the user asks about these topics.

---

**`config-template.json` — define your runtime config keys**

If it exists, show the user its current contents. Tell them:
- Add your config key names with empty values — actual values are set in the App Service console UI and injected via `APP_SERVICE_CONFIG` env variable
- If your app has no runtime config, leave it as `{}`

---

**`.gitignore` — exclude files that should not be pushed**

If missing or empty, tell the user to add at minimum:
```
venv/
.venv/
__pycache__/
*.pyc
.env
*.log
.DS_Store
node_modules/
```
Also add any local data files, model weights, or credentials.

---

**`azure-pipelines.yml` — do NOT touch**

Tell them: "Leave this file exactly as it is. It is fully managed by the platform — any changes will break your pipeline."

---

### Step 3: Ask user what they need help with

After walking through the above, ask:
"Which parts do you need help with? For example:
- Cleaning up template files from `src/` and adding your code
- Updating `environment.yml` with your dependencies
- Setting up `config-template.json`
- Setting up Foundry data access
- Something else"

For each thing the user asks help with:
1. Read the relevant file first so you understand what's currently there
2. Read the relevant resource file from `resources/` for platform guidance
3. Tell the user exactly what they need to change and why — show them the target content
4. **Do NOT edit or write any files yourself** — the user must make all code changes
5. Wait for the user to confirm they've made the change before moving on

Tell the user: "Let me know when you've made all your changes and are ready to deploy."

**Important:** If the user shares their own app code (e.g. `@app.py`) and asks you to help make it deployment-ready, do NOT copy or modify their files. Instead, tell them exactly what they need to do:
- Which file to rename/replace (e.g. "Rename your `app.py` to `Welcome.py` and move it into `src/`")
- What to add to `environment.yml` (list the packages they need to add)
- Whether the Dockerfile needs any changes (usually it doesn't)
Then wait for them to make those changes themselves.

---

## Phase 4: Deploy

Tell the user: "Let me check your files before you push."

Read and verify:
```bash
cat Dockerfile
cat environment.yml
find src/ -type f | sort
```

Check for:
- `Dockerfile` — correct base image `mambaorg/micromamba:2.5.0`, `EXPOSE 8080`, correct CMD for framework
- `environment.yml` — `conda-forge` channel with `nodefaults`, packages listed, Python pinned
- `src/` — entry point file exists (`Welcome.py` for Streamlit, `app.py` for Dash, `server.R` for Shiny, `main.py` for FastAPI)
- `azure-pipelines.yml` — NOT modified

If anything is wrong, tell the user exactly what to fix. Do NOT fix it automatically.

Once everything looks good, tell the user:

"Everything looks correct. When you're ready, commit and push yourself:
```
git add .
git commit -m 'describe your changes'
git push
```
`git push` will prompt for credentials — use **Generate Git Credentials** from the ADO repo Clone dialog.

**What happens after push:**
- All branches → pipeline builds Docker image (validates your code compiles and runs)
- `main` branch only → pipeline also pushes image to ECR → AWS ECS deploys it automatically

**If you need separate dev and prod environments:**
You'll need two separate apps (e.g. `my-app-dev` and `my-app-prod`). In the console, go to the dev app config → enable 'Allow other apps to push images to this app'. Read `resources/03-best-practices.md` for the multi-stage pipeline YAML."

**Do NOT run git commit or git push yourself.**

Tell the user: "Let me know when you've pushed. Then use `/uptimize-debug` to monitor the pipeline and debug any failures."
