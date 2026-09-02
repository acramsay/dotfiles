import { homedir } from "node:os"
import { join } from "node:path"
import type { Part } from "@opencode-ai/sdk"

export type ScanTarget = {
  partID: string
  messageID: string
  kind: "text" | "tool"
  get: () => string
  set: (v: string) => void
}

// Picks the scannable spans out of a transform message array: user text parts
// and completed tool outputs. Completed-only; error/running states carry no
// output text yet, and inputs stay untouched by design.
export function collectTargets(messages: Array<{ info: { id: string; role: string }; parts: Part[] }>): ScanTarget[] {
  const out: ScanTarget[] = []
  for (const m of messages) {
    for (const p of m.parts) {
      if (m.info.role === "user" && p.type === "text" && !p.synthetic && !p.ignored) {
        out.push({ partID: p.id, messageID: m.info.id, kind: "text", get: () => p.text, set: (v) => { p.text = v } })
      } else if (m.info.role === "assistant" && p.type === "tool" && p.state.status === "completed") {
        out.push({ partID: p.id, messageID: m.info.id, kind: "tool", get: () => p.state.output, set: (v) => { if (p.state.status === "completed") p.state.output = v } })
      }
    }
  }
  return out
}

export type Finding = {
  rule: string
  startLine: number // 1-based
  startCol: number // 1-based
  match: string
}

export const veilHome = join(
  process.env.XDG_CACHE_HOME ?? join(homedir(), ".cache"),
  "veil",
)

export async function checkBinary(binary = "gitleaks"): Promise<boolean> {
  try {
    const proc = Bun.spawn([binary, "version"], { stdout: "ignore", stderr: "ignore" })
    return (await proc.exited) === 0
  } catch {
    return false
  }
}

// Findings are spliced out via `match` (not line/col) because multi-line
// matches have imprecise end columns in gitleaks' report.
export async function scanText(text: string, binary = "gitleaks"): Promise<Finding[]> {
  const args = [binary, "stdin", "--no-banner", "-l", "fatal", "-f", "json", "-r", "-"]
  const proc = Bun.spawn(args, { stdin: "pipe", stdout: "pipe", stderr: "ignore" })
  proc.stdin.write(text)
  proc.stdin.end()
  const code = await proc.exited
  if (code !== 0 && code !== 1) throw new Error(`gitleaks exited with code ${code}`)
  const out = (await new Response(proc.stdout).text()).trim()
  const found = (JSON.parse(out || "[]")) as Array<{
    RuleID: string
    StartLine: number
    StartColumn: number
    Match: string
  }>
  return found.map((f) => ({
    rule: f.RuleID,
    startLine: f.StartLine,
    startCol: f.StartColumn,
    match: f.Match,
  }))
}

export function redactText(text: string, findings: Finding[]): string {
  let out = text
  for (const f of findings) {
    out = out.split(f.match).join(`[REDACTED:${f.rule}]`)
  }
  return out
}

export type AuditEvent = {
  ts: number
  outcome: "redact" | "clean" | "fail-open"
  kind: "text" | "tool"
  messageID: string
  partID: string
  scanMs?: number
  rules?: string[]
  error?: string
}

export async function appendAudit(path: string, event: AuditEvent): Promise<void> {
  try {
    const { appendFile } = await import("node:fs/promises")
    await appendFile(path, JSON.stringify(event) + "\n")
  } catch {}
}
