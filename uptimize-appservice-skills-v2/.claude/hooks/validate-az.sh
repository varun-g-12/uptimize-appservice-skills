#!/bin/bash
# Claude Code PreToolUse Hook — UPTIMIZE App Service Plugin
# Validates az commands against a read-only whitelist.
# Triggered only for commands matching "Bash(az *)" in settings.json.
# Non-az commands (git, ls, pip, etc.) bypass this hook entirely.

HOOK_INPUT=$(cat)
COMMAND=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- BLOCKED patterns (checked first) ---
BLOCKED_PATTERNS=(
  "az.*delete"
  "az.*remove"
  "az.*create"
  "az.*update"
  "az.*set "
  "az deployment"
  "az role assignment"
  "az webapp"
  "az container"
  "az aks"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    python3 -c "
import json, sys
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'PreToolUse',
    'permissionDecision': 'deny',
    'permissionDecisionReason': 'Blocked: \"$pattern\" matches a dangerous write/delete pattern. Only read-only az diagnostic commands are allowed.'
  }
}))
"
    exit 0
  fi
done

# --- ALLOWED patterns ---
ALLOWED_PATTERNS=(
  "^az --version"
  "^az version"
  "^az login"
  "^az logout"
  "^az account show"
  "^az extension add --name azure-devops"
  "^az extension show"
  "^az devops configure"
  "^az pipelines show"
  "^az pipelines list"
  "^az pipelines runs list"
  "^az devops invoke.*--area build.*--resource timeline"
  "^az devops invoke.*--area build.*--resource logs"
)

for pattern in "${ALLOWED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    exit 0
  fi
done

# Not in whitelist — block with explanation
python3 -c "
import json
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'PreToolUse',
    'permissionDecision': 'deny',
    'permissionDecisionReason': 'Not in allowlist. Only read-only az commands are permitted: az login, az account show, az pipelines show/list/runs, az devops invoke (timeline/logs), az devops configure.'
  }
}))
"
exit 0
