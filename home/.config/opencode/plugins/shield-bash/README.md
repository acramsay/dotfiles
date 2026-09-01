# shield-bash

Second-session gate for bash tool calls. A dedicated opencode "judge" session is created at
first command and judges every bash via `session.prompt`; the verdict allows or denies the
command through opencode's `tool.execute.before` hook.

## Files

- `plugin.ts` — the hook, audit, cache, and failure-mode glue (`plugins/shield-bash.ts` imports this)
- `lib.ts` — `POLICY_PROMPT`, verdict parsing, cache (TTL + size-capped), audit writer, default config
- `fixtures.json` — expected allow/deny fixture commands
- `test.ts` — integration test against a running `opencode serve`
- `../../shield-bash.json` — config: `providerID`, `modelID`, `failure`

## Config

Model/provider comes from `shield-bash.json` (env `SHIELD_BASH_MODEL="provider/model"` overrides).
`failure` decides what happens when the judge session errors:

- `deny` (default)
- `allow`
- `ask` — defer to opencode's normal permission evaluation

A verdict is cached for `SHIELD_BASH_TTL_HOURS` (default 24) in `~/.cache/shield-bash/verdicts.json`.
Every judgment is appended to `~/.cache/shield-bash/audit.jsonl`.

## Wanted features (blocked upstream)

**Tri-state "ask".** Binary allow/deny works today, but triage-worthy commands (`git push`,
sudo-ish operations, `npm publish`, ambiguous rm) should defer to the normal permission prompt.
This is impossible as long as the `permission.ask` hook stays unwired: `tool.execute.before`
can only throw (deny) or defer (config evaluates), so a layered plugin can narrow but never
reinsert a prompt.

**Replace mode.** If `permission.ask` fires, the plugin could own the decision instead of
layering on opencode's permission config.

## Current limitations

- opencode's `permission.ask` hook is declared in `@opencode-ai/plugin` types but never invoked
  by the server (checked v1.18.x tags and the `dev` branch — no `plugin.trigger("permission.ask")`
  call site). Anything relying on it no-ops at runtime.
- Therefore only `layered` behavior is possible today; an `ask` verdict would degrade to whatever
  opencode's config resolves (currently `"*": "allow"` in opencode.json).

## Relevant issue

- Upstream: [anomalyco/opencode#7006](https://github.com/anomalyco/opencode/issues/7006) —
  "`permission.ask` plugin hook is defined but not triggered". Candidate PRs: #30509, #42633,
  #19453. Once one of these inverts, extend the model/verdict code to tri-state.

## Tests

`bun test plugins/shield-bash/test.ts` — drive fixture commands through a persistent judge
session on the running opencode web server (`opencode serve --port 4096 --hostname 127.0.0.1`).
A fresh session per fixture keeps earlier commands out of the judge's context; serial tests plus
one retry absorb provider flakiness.
