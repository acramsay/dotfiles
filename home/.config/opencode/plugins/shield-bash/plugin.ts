import type { Plugin } from "@opencode-ai/plugin"
import { mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { defaultConfig, parseVerdictText, POLICY_PROMPT, readCache, saveCache } from "./lib"

type FailureMode = "allow" | "deny" | "ask"

const DEFAULT_FAILURE: FailureMode = "deny"
const MODEL_FALLBACK = { providerID: "vercel", modelID: "zai/glm-5.3-flash" }

// Gates every bash command by prompting a second opencode session with the
// policy in lib.ts.
export const ShieldBash: Plugin = async ({ client, directory }) => {
  const config = defaultConfig()
  mkdirSync(dirname(config.cachePath), { recursive: true })
  const cache = await readCache(config.cachePath, config.cacheTtlMs)

  // Loaded lazily. The server serves no requests until plugin init returns,
  // so a client call at init time would deadlock.
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
    // A child of the caller, so the TUI's child-session nav reaches it and it
    // stays out of the session list and tied to the parent's lifecycle.
    const judgeSession = await client.session.create({
      body: { parentID: parentSessionID, title: "Shield Bash" },
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
        if (failureMode === "allow") return
        // The permission.ask hook never fires upstream, so ask defers to config.
        if (failureMode === "ask") return
        throw new Error(
          `shield-bash denied (judge unavailable, fail-closed).\nDetail: ${reason}`,
        )
      }

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
