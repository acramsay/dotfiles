# veil

Redacts secrets before they are sent to the upstream LLM. Per turn, the
`experimental.chat.messages.transform` hook hands opencode plugins the full message array; this
plugin scans each **user text part** and each **completed tool output** once (memoized by part ID
per server process) and splices out matches as `[REDACTED:<rule-id>]`.

Tool outputs are the primary leak vector (`cat .env`, `gh auth token`, PEM files) — much of what
the model sees arrives via completed ToolParts, not typing. Tool **inputs**, `ToolStateError`
outputs, and anything still pending/running stay untouched (no output text to scrub yet).

Detection is 100% local: [gitleaks](https://github.com/gitleaks/gitleaks) is spawned with
`gitleaks stdin` — no temp files, no network, ~25–35ms per span. No generative model involved.

## Non-goals

- Assistant text parts are never scanned (they are the model's own prior output).
- Nothing ever blocks a prompt: any scanner error is logged and the text passes through (fail-open).

## Files

- `plugin.ts` — the transform hook, scan gating, audit/write glue (`plugins/veil.ts` imports this)
- `lib.ts` — gitleaks stdin spawning, finding parsing, `[REDACTED:<rule>]` splicing, target
  collection (user text + completed tool outputs), audit writer
- `fixtures.json` — named texts with expected rule IDs (redact) and hard negatives (clean)
- `test.ts` — `bun test ./plugins/veil/test.ts` (no opencode server needed)

## Audit

Every scan appends a JSON line to `~/.cache/veil/audit.jsonl`:

```json
{"ts":1788298584251,"outcome":"redact","kind":"tool","messageID":"msg_...","partID":"prt_...","scanMs":27,"rules":["github-pat"]}
```

`outcome` is `redact`, `clean`, or `fail-open`; `kind` is `text` or `tool`. The secret itself is
never logged — only rule IDs.

## Failure modes

- gitleaks binary missing at plugin init → plugin disables itself and logs a warn to opencode.
- Any scan-time error (spawn, non-{0,1} exit, bad JSON) → `fail-open`, prompt passes through.

## Known behavior

- The transform mutates only the outgoing copy of the message; the stored session retains the raw
  text, and because part IDs are memoized, a span is scanned at most once per server process.
- Tool inputs, and tool outputs in `error`/`pending`/`running` states, pass through unscrubbed.
- gitleaks' default ruleset deliberately allowlists examples (`AKIA...EXAMPLE`) and entropy-filters
  low-variance strings — see `fixtures.json` for shapes that reliably do/don't match.
- JWTs are redacted as secrets by gitleaks' `jwt` rule; they are not hard negatives.
