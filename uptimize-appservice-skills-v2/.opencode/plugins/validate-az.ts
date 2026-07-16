// OpenCode Plugin — UPTIMIZE App Service Safety Hook
// Validates az commands against a read-only whitelist.
// Same logic as .claude/hooks/validate-az.sh for Claude Code.

const BLOCKED_PATTERNS = [
  /az.*delete/i,
  /az.*remove/i,
  /az.*create/i,
  /az.*update/i,
  /az.*set /i,
  /az\s+deployment/i,
  /az\s+role\s+assignment/i,
  /az\s+webapp/i,
  /az\s+container/i,
  /az\s+aks/i,
]

const ALLOWED_PATTERNS = [
  /^az --version/i,
  /^az version/i,
  /^az login/i,
  /^az logout/i,
  /^az account show/i,
  /^az extension add --name azure-devops/i,
  /^az extension show/i,
  /^az devops configure/i,
  /^az pipelines show/i,
  /^az pipelines list/i,
  /^az pipelines runs list/i,
  /^az pipelines run/i,
  /^az devops invoke.*--area build.*--resource timeline/i,
  /^az devops invoke.*--area build.*--resource logs/i,
]

export const ValidateAz = async ({
  project,
  client,
  $,
  directory,
  worktree,
}: {
  project: unknown
  client: unknown
  $: unknown
  directory: string
  worktree: string
}) => {
  return {
    "tool.execute.before": async (
      input: { tool: string },
      output: { args: Record<string, unknown> },
    ) => {
      if (input.tool !== "bash") return

      const cmd = String(output.args.command || "").trim()
      if (!cmd.startsWith("az ") && cmd !== "az") return

      for (const pattern of BLOCKED_PATTERNS) {
        if (pattern.test(cmd)) {
          throw new Error(
            `Blocked: "${pattern.source}" matches a dangerous write/delete pattern. Only read-only az diagnostic commands are allowed.`,
          )
        }
      }

      for (const pattern of ALLOWED_PATTERNS) {
        if (pattern.test(cmd)) return
      }

      throw new Error(
        "Not in allowlist. Only read-only az commands are permitted: az login, az account show, az pipelines show/list/runs, az devops invoke (timeline/logs), az devops configure.",
      )
    },
  }
}
