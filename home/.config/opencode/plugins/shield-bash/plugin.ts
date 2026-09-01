import type { Plugin } from "@opencode-ai/plugin"
import { mkdirSync } from "node:fs"
import { dirname } from "node:path"
import { fileURLToPath } from "node:url"
import {
  appendAudit,
  defaultConfig,
  parseVerdictText,
  POLICY_PROMPT,
  readCache,
  saveCache,
} from "./lib"
import type { AuditEvent, Verdict } from "./lib"

type FailureMode = "allow" | "deny" | "ask"

// Second-session gate for bash tool calls — a dedicated opencode session is
// created at first command and judges every bash via `session.prompt`.
// Model/provider comes from shield-bash.json; env SHIELD_BASH_MODEL overrides.
// `failure` in shield-bash.json decides what a judge error does:
//   "deny" (default) / "allow" / "ask" = defer to opencode's config
const DEFAULT_FAILURE: FailureMode = "deny"
const MODEL_FALLBACK = { providerID: "vercel", modelID: "zai/glm-5.3-flash" }

type Logger = (level: "info" | "warn" | "error", message: string, extra?: Record<string, unknown>) => Promise<void>

export const ShieldBash: Plugin = async ({ client, directory }) => {
  const log: Logger = (level, message, extra) =>
    client.app
      .log({ body: { service: "shield-bash", level, message, extra }, query: { directory } })
      .then(() => {})

  const config = defaultConfig()
  mkdirSync(dirname(config.cachePath), { recursive: true })
  mkdirSync(dirname(config.auditPath), { recursive: true })
  const cache = await readCache(config.cachePath, config.cacheTtlMs)

  // Audit helper: one shape for every outcome, to keep the hook below linear.
  const audit = (event: {
    outcome: AuditEvent["outcome"]
    command: string
    cached: boolean
    started: number
    verdict?: Partial<Verdict>
  }) =>
    appendAudit(config.auditPath, {
      ts: Date.now(),
      command: event.command,
      outcome: event.outcome,
      cache: event.cached ? "hit" : "model",
      verdictMs: Date.now() - event.started,
      ...event.verdict,
    })

  // Model/provider + failure mode: committed JSON first, env second, fallback third.
  let model = MODEL_FALLBACK
  let failureMode: FailureMode = DEFAULT_FAILURE
  try {
    const file = fileURLToPath(new URL("../../../shield-bash.json", import.meta.url))
    const json = (await Bun.file(file).json()) as {
      providerID?: string
      modelID?: string
      failure?: string
    }
    if (json.providerID && json.modelID) model = json as typeof model
    if (json.failure === "allow" || json.failure === "deny" || json.failure === "ask") {
      failureMode = json.failure
    }
  } catch {}
  const envOverride = process.env.SHIELD_BASH_MODEL?.split("/")
  if (envOverride?.length === 2) model = { providerID: envOverride[0], modelID: envOverride[1] }

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
    await log("info", "judge session created", { judgeSessionID, model })
    return judgeSessionID
  }

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return
      const command = output.args.command
      if (typeof command !== "string" || command.trim() === "") return

      const started = Date.now()
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
        if (failureMode === "allow") {
          await log("warn", "judge session failed, allowing (fail-open)", { command, error: reason })
          await audit({ outcome: "fail-open", command, cached: Boolean(cached), started, verdict: { reason } })
          return
        }
        if (failureMode === "ask") {
          await log("warn", "judge session failed, deferring to opencode config (fail-ask)", {
            command,
            error: reason,
          })
          await audit({ outcome: "fail-ask", command, cached: Boolean(cached), started, verdict: { reason } })
          return
        }
        await log("error", "judge session failed, denying (fail-closed)", { command, error: reason })
        await audit({ outcome: "fail-closed", command, cached: Boolean(cached), started, verdict: { reason } })
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
        await log("warn", "bash denied", { command, verdict, cacheHit: Boolean(cached) })
        await audit({ outcome: "deny", command, cached: Boolean(cached), started, verdict })
        const category = verdict.category ? `\nCategory: ${verdict.category}` : ""
        const alt = verdict.alternative ? `\nAlternative: ${verdict.alternative}` : ""
        throw new Error(
          `shield-bash (session-based safety gate for unattended bash) denied.${category}\nReason: ${verdict.reason}${alt}`,
        )
      }
      await log("info", "bash allowed", { command, verdictMs: Date.now() - started })
      await audit({ outcome: "allow", command, cached: Boolean(cached), started })
    },
  }
}
