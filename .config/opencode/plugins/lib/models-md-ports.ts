import { randomUUID } from "node:crypto"
import { existsSync, mkdirSync, readdirSync, readFileSync, renameSync, unlinkSync, writeFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

// Discovery directory for models-md.ts's status server. Multiple opencode
// processes can run concurrently against the same config, each with its own
// server instance -- there is no single well-known port. Every instance
// binds an ephemeral port and writes a record here; the sidebar TUI
// (models-md-tui.tsx) reads every live record instead of assuming one port.
const PORTS_DIR = join(homedir(), ".local/state/opencode/models-md/ports")

export type PortRecord = { port: number; pid: number; started_at: number }

export const isPidAlive = (pid: number): boolean => {
  try {
    process.kill(pid, 0)
    return true
  } catch (err) {
    // EPERM means the process exists but we lack permission to signal it.
    return (err as NodeJS.ErrnoException).code === "EPERM"
  }
}

const parsePortRecord = (content: string): PortRecord | null => {
  try {
    const parsed = JSON.parse(content) as Partial<PortRecord>
    if (typeof parsed.port !== "number" || typeof parsed.pid !== "number") return null
    return { port: parsed.port, pid: parsed.pid, started_at: typeof parsed.started_at === "number" ? parsed.started_at : 0 }
  } catch {
    return null
  }
}

const readRecordFile = (path: string): PortRecord | null => {
  try {
    return parsePortRecord(readFileSync(path, "utf-8"))
  } catch {
    return null
  }
}

// Remove sibling port files whose owning process is provably dead. Legacy
// hygiene, run opportunistically when a new server starts.
const sweepDeadPortFiles = (): void => {
  let entries: string[]
  try {
    entries = readdirSync(PORTS_DIR)
  } catch {
    return
  }
  for (const entry of entries) {
    if (!entry.endsWith(".json")) continue
    const path = join(PORTS_DIR, entry)
    const record = readRecordFile(path)
    try {
      if (record === null || !isPidAlive(record.pid)) unlinkSync(path)
    } catch {
      // Racing another instance's sweep, or a permission issue -- fine, retried next startup.
    }
  }
}

// Called once by a status server right after it binds. Writes this
// instance's port under a random filename (never the pid -- opencode is
// known to double-invoke a plugin factory within a single process, and two
// instances in the same process must not overwrite each other's file).
export const writePortFile = (port: number): void => {
  mkdirSync(PORTS_DIR, { recursive: true })
  sweepDeadPortFiles()
  const path = join(PORTS_DIR, `${randomUUID()}.json`)
  const tmpPath = `${path}.tmp`
  const record: PortRecord = { port, pid: process.pid, started_at: Date.now() }
  writeFileSync(tmpPath, JSON.stringify(record))
  renameSync(tmpPath, path)
}

// Every live status server instance for this config, newest first.
export const readLivePortRecords = (): PortRecord[] => {
  if (!existsSync(PORTS_DIR)) return []
  let entries: string[]
  try {
    entries = readdirSync(PORTS_DIR)
  } catch {
    return []
  }
  const records: PortRecord[] = []
  for (const entry of entries) {
    if (!entry.endsWith(".json")) continue
    const record = readRecordFile(join(PORTS_DIR, entry))
    if (record && isPidAlive(record.pid)) records.push(record)
  }
  return records.sort((a, b) => b.started_at - a.started_at)
}
