/** @jsxImportSource @opentui/solid */
import type { TuiPlugin, TuiPluginApi } from "@opencode-ai/plugin/tui"
import { createSignal, onCleanup, For, Show } from "solid-js"
import { readLivePortRecords } from "./lib/models-md-ports"

// Sidebar view for models-md.ts: shows which model-instruction files were
// applied for the active session, and whether the plugin's status server is
// reachable. Talks to models-md.ts over loopback -- undocumented
// TuiPlugin/slots API, so this is a best-effort mirror of opencode's own
// built-in sidebar sections (e.g. feature-plugins/sidebar/todo.tsx).
//
// Multiple opencode processes can run concurrently, each with its own
// models-md status server on its own port. This session's data lives in
// whichever process actually ran the LLM turn, so every poll tries every
// live server (via lib/models-md-ports.ts) until one has this session.

const POLL_INTERVAL_MS = 15_000
const RETRY_BASE_MS = 1_000
const RETRY_MAX_MS = 8_000
const FETCH_TIMEOUT_MS = 1_000

type StatusEntry = {
  providerID: string
  modelID: string
  files: string[]
  updatedAt: number
  error?: string
}

async function fetchWithTimeout(url: string): Promise<Response> {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS)
  try {
    return await fetch(url, { signal: controller.signal })
  } finally {
    clearTimeout(timer)
  }
}

// Tries every live status server in turn. `reachable` is true as soon as any
// server answers, even if none of them know this session -- that still means
// the plugin is running, just not for a turn in this process.
async function fetchStatus(sessionID: string): Promise<{ entry?: StatusEntry; reachable: boolean }> {
  let reachable = false
  for (const record of readLivePortRecords()) {
    try {
      const res = await fetchWithTimeout(
        `http://127.0.0.1:${record.port}/status?sessionId=${encodeURIComponent(sessionID)}`,
      )
      reachable = true
      if (res.ok) return { entry: (await res.json()) as StatusEntry, reachable: true }
    } catch {
      // Unreachable or stale port -- try the next one.
    }
  }
  return { reachable }
}

function View(props: { api: TuiPluginApi; session_id: string }) {
  const theme = () => props.api.theme.current
  const [status, setStatus] = createSignal<StatusEntry | undefined>(undefined)
  const [connected, setConnected] = createSignal(false)
  const [collapsed, setCollapsed] = createSignal(false)

  let disposed = false
  let retryDelay = RETRY_BASE_MS
  let timer: ReturnType<typeof setTimeout> | undefined

  const scheduleNext = (delay: number) => {
    if (disposed) return
    clearTimeout(timer)
    timer = setTimeout(refresh, delay)
  }

  // Refetch is triggered by turn-completion events (the moment the server
  // plugin's data can actually change) plus a slow poll as a backstop for
  // first render and any missed event.
  async function refresh() {
    const { entry, reachable } = await fetchStatus(props.session_id)
    if (disposed) return
    setConnected(reachable)
    if (reachable) {
      retryDelay = RETRY_BASE_MS
      if (entry) setStatus(entry)
      scheduleNext(POLL_INTERVAL_MS)
    } else {
      scheduleNext(retryDelay)
      retryDelay = Math.min(retryDelay * 2, RETRY_MAX_MS)
    }
  }

  refresh()

  const offIdle = props.api.event.on("session.idle", () => refresh())
  const offMessage = props.api.event.on("message.updated", () => refresh())

  onCleanup(() => {
    disposed = true
    clearTimeout(timer)
    offIdle()
    offMessage()
  })

  const fileCount = () => status()?.files.length ?? 0

  return (
    <box>
      {/* Clicking the header row collapses/expands the file list, mirroring
          AFT's own sidebar section toggle. */}
      <box
        flexDirection="row"
        gap={1}
        justifyContent="space-between"
        onMouseDown={() => setCollapsed((x) => !x)}
      >
        <box flexDirection="row" gap={1}>
          <text fg={theme().text}>
            <b>
              {collapsed() ? "▶ " : "▼ "}Models MD
            </b>
          </text>
          <text fg={connected() ? theme().success : theme().error}>●</text>
        </box>
        <text fg={theme().textMuted}>{fileCount()}</text>
      </box>
      <Show when={!collapsed()}>
        <Show when={status()?.error}>{(error) => <text fg={theme().error}>{error()}</text>}</Show>
        <For each={status()?.files ?? []}>
          {(file) => (
            <text fg={theme().textMuted} wrapMode="none">
              {file}
            </text>
          )}
        </For>
      </Show>
    </box>
  )
}

const tui: TuiPlugin = async (api) => {
  api.slots.register({
    // Built-in "Context" section uses order 100; sit directly below it.
    order: 150,
    slots: {
      sidebar_content(_ctx, props) {
        return <View api={api} session_id={props.session_id} />
      },
    },
  })
}

export default { id: "models-md", tui }
