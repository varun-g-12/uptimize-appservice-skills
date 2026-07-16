# Known Pipeline Issues and Fixes

Check this file first before querying MCPs. If the error is here, no MCP call needed.

---

## Build Step Failures

### Package not found / Could not solve for environment specs

**Error pattern:**
```
critical libmamba Could not solve for environment specs
```

**Cause:** A package in `environment.yml` is misspelled, doesn't exist on conda-forge, or has a version conflict.

**Fix:**
1. Check the package name spelling — conda-forge names differ from pip sometimes (e.g. `scikit-learn` not `sklearn`)
2. If pip-only, move to the `pip:` subsection in `environment.yml`
3. If version conflict, relax version pins

---

### YAML parse error in environment.yml

**Error pattern:**
```
critical libmamba yaml-cpp: error at line X, column Y
```

**Cause:** Malformed YAML in `environment.yml` — most commonly a missing space after the `-` in a list item (e.g. `-package-name` instead of `- package-name`).

**Fix:** Check the line number in the error. Ensure all list items have a space after the dash: `- package-name`

---

### Dockerfile syntax error

**Error pattern:**
```
failed to build: dockerfile parse error
```

**Cause:** Invalid Dockerfile syntax.

**Fix:** Check the Dockerfile — common issues are missing quotes in CMD array, wrong base image tag, or missing `\` line continuation.

---

### COPY failed: file not found

**Error pattern:**
```
COPY failed: file not found in build context
```

**Cause:** The file or directory referenced in the Dockerfile COPY doesn't exist in the repo.

**Fix:** Ensure `src/` directory exists and the entry point file matches the name in CMD. Check for typos in filenames.

---

### Port not 8080

**Error pattern:** App deploys but is unreachable / returns 502.

**Cause:** App is listening on a port other than 8080.

**Fix:** Make sure the app config and Dockerfile use port 8080. For Streamlit: `ENV STREAMLIT_SERVER_PORT="8080"`. For Dash/FastAPI: hardcode `port=8080` in the app.

---

## Non-Blocking Warnings (Safe to Ignore)

### Platform flag warning

```
WARN: FromPlatformFlagConstDisallowed: FROM --platform flag should not use constant value "linux/x86-64"
```

**Safe to ignore.** Build still succeeds.

### ECR cache miss on first build

```
ERROR: failed to configure registry cache importer: ... not found
```

**Safe to ignore.** Happens on first build — no cached image yet. Subsequent builds use the cache.

### Docker credentials stored unencrypted

```
WARNING! Your credentials are stored unencrypted
```

**Safe to ignore.** This is on the build agent, not your machine.

---

## Push Step Issues

### Push skipped (not on main)

**Cause:** The Docker push to ECR only runs on the `main` branch. Feature branches build but do not push.

**Fix:** If you want to deploy to production, push or merge to `main`.

---

### Push failed: authorization token expired

**Error pattern:**
```
denied: Your authorization token has expired
```

**Cause:** AWS credentials expired during a very long build.

**Fix:** Re-trigger the pipeline manually or push an empty commit to restart it.

---

## Checkout Step Issues

### Repository not found

**Error pattern:**
```
remote: TF401019: The Git repository with name or identifier ... does not exist
```

**Cause:** Pipeline is pointing to a repo that doesn't exist or was renamed.

**Fix:** This is a platform configuration issue — contact the UPTIMIZE App Service team.

---

## Unknown Issues

If the error is not listed here:
1. Check App Service Issues MCP (if configured)
2. Check UPTIMIZE Docs MCP (if configured)
3. Use Claude's knowledge based on the error message
4. If still unresolved — share the full error log with the UPTIMIZE App Service team
