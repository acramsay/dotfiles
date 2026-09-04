import type { Plugin } from "@opencode-ai/plugin"
import { mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { defaultConfig, parseVerdictText, POLICY_PROMPT, readCache, saveCache } from "./lib"

type FailureMode = "allow" | "deny" | "ask"

// Second-session gate for bash tool calls — a dedicated opencode session is
// created at first command and judges every bash via `session.prompt`.
// Model/provider comes from shield-bash.json; env SHIELD_BASH_MODEL overrides.
// `failure` in shield-bash.json decides what a judge error does:
//   "deny" (default) / "allow" / "ask" = defer to opencode's config
const DEFAULT_FAILURE: FailureMode = "deny"
const MODEL_FALLBACK = { providerID: "vercel", modelID: "zai/glm-5.3-flash" }

export const ShieldBash: Plugin = async ({ client, directory }) => {
  const config = defaultConfig()
  mkdirSync(dirname(config.cachePath), { recursive: true })
  const cache = await readCache(config.cachePath, config.cacheTtlMs)

  // Model/provider + failure mode: config JSON first, env second, fallback third.
  // Loaded lazily on first bash — client calls during plugin init deadlock startup
  // (the server can't serve requests until bootstrap, which awaits plugin init).
  let model = MODEL_FALLBACK
  let failureMode: FailureMode = DEFAULT_FAILURE
  let configLoaded: Promise<void> | null = null
  const loadConfig = () => {
    if (configLoaded) return configLoaded
    configLoaded = (async () => {
      try {
        const path = await client.path.get({ query: { directory } })
        if (path.data?.config) {
          const file = join(path.data.config, "shield-bash.json")
          const json = (await Bun.file(file).json()) as {
            providerID?: string
            modelID?: string
            failure?: string
          }
          if (json.providerID && json.modelID) model = json as typeof model
          if (json.failure === "allow" || json.failure === "deny" || json.failure === "ask") {
            failureMode = json.failure
          }
        }
      } catch {}
      const envOverride = process.env.SHIELD_BASH_MODEL?.split("/")
      if (envOverride?.length === 2) model = { providerID: envOverride[0], modelID: envOverride[1] }
    })()
    return configLoaded
  }

  let judgeSessionID: string | null = null
  const ensureJudgeSession = async (parentSessionID: string) => {
    if (judgeSessionID) return judgeSessionID
    const parent = await client.session.get({ path: { id: parentSessionID }, query: { directory } })
    const parentTitle = parent.data?.title ?? "session"
    const judgeSession = await client.session.create({
      body: { title: `(bash) ${parentTitle}` },
      query: { directory },
    })
    if (judgeSession.error || !judgeSession.data) {
      throw new Error(`failed to create judge session: ${JSON.stringify(judgeSession.error)}`)
    }
    judgeSessionID = judgeSession.data.id
    return judgeSessionID
  }

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return
      const command = output.args.command
      if (typeof command !== "string" || command.trim() === "") return
      await loadConfig()

      const cached = cache.get(command)
      let verdict
      try {
        if (cached) {
          verdict = cached.verdict
        } else {
          const sessID = await ensureJudgeSession(input.sessionID)
          const response = await client.session.prompt({
            path: { id: sessID },
            body: {
              system: POLICY_PROMPT,
              parts: [{ type: "text", text: `Command: ${command}\nReturn the JSON verdict.` }] as const,
              model,
            } as never,
            query: { directory },
          })
          if (response.error || !response.data) {
            throw new Error(`judge session error: ${JSON.stringify(response.error)}`)
          }
          const textPart = response.data.parts.find((p) => p.type === "text")
          if (!textPart || textPart.type !== "text") throw new Error("judge returned no text")
          verdict = parseVerdictText((textPart as { type: "text"; text: string }).text)
        }
      } catch (err) {
        const reason = err instanceof Error ? err.message : String(err)
        if (failureMode === "allow") return // fail-open
        if (failureMode === "ask") return // fail-ask: defer to opencode config
        throw new Error(
          `shield-bash denied (judge unavailable, fail-closed).\nDetail: ${reason}`,
        )
      }

      // Cache every verdict (both allow and deny) so repeat commands skip the model.
      if (!cached) {
        cache.set(command, { verdict, ts: Date.now() })
        await saveCache(config.cachePath, cache)
      }
      if (verdict.decision === "deny") {
        const category = verdict.category ? `\nCategory: ${verdict.category}` : ""
        const alt = verdict.alternative ? `\nAlternative: ${verdict.alternative}` : ""
        throw new Error(
          `shield-bash (session-based safety gate for unattended bash) denied.${category}\nReason: ${verdict.reason}${alt}`,
        )
      }
    },
  }
}
