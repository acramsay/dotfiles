---
name: reflect
description: Mine the current session for durable learnings and propose dotfiles improvements (skills, opencode config) as a discussion. Use when the user says "reflect", typically at the end of a session.
---

# Reflect

Review the just-completed session through three parallel reviewer lenses, synthesize the findings yourself, and present proposals as a discussion. Proposals target the dotfiles repo (skills and opencode config primarily) or, when a learning is project-specific, the session project's own files. Never apply changes from this skill; the user picks what to apply afterward.

## Process

### 0. Reorient

The session's original task is complete. The task now is meta: extract durable learnings from the conversation just completed. If the conversation was trivial or produced only one-offs, say so and stop - one-offs are not learnings.

If the session was long or already compressed (step 1 reports pruned tokens or a large export), first compress the session's bulk yourself with the compress tool. Write the summary through a reflection lens: preserve decisions, user corrections, dead ends, and workflow moments; squeeze implementation detail. Skip on short sessions.

### 1. Export the session

Run `scripts/export-context.sh` from this skill's directory. Optional argument: a session ID, to review a session other than the current one. It prints:

- `export.json` - full transcript: messages, tool calls and their outputs
- `map.txt` - one line per message; the navigation index
- `dcp.json` - DCP pruning history: compress summaries and stats
- the dotfiles repo root, resolved from the `~/Taskfile.yaml` symlink

Verify the export is this conversation: its first user message matches the opening task. Compression changes what you hold in context, never what export.json contains. On mismatch, find the right session via `opencode session list` and rerun with its ID. If export fails outright, write a tight digest of the session and pass that to reviewers instead.

Subagent work appears as separate sessions in `opencode session list` (titles like `(@general subagent)`). Reviewers can export those with the same script if the main thread references them.

### 2. Spawn three reviewers

One message, three `task` calls, `subagent_type: general`. Tell each reviewer to read its template file and follow it, passing the four values from step 1 into the template's placeholders:

- Judgment lens: `references/judgment-reviewer.md`
- Tooling lens: `references/tooling-reviewer.md`
- Divergent lens: `references/divergent-reviewer.md`

Reviewers write no files and return findings in their task response.

### 3. Synthesize

You synthesize; you were present, the reviewers were not. Spot-verify every citation against your own memory, and when memory and a citation conflict, drill into export.json before trusting either. Where step 0 compressed a range, your memory of it is your own digest - verify citations from compressed ranges against export.json directly. Merge into one proposals list and drop what does not survive verification. Route each proposal per Proposal targets below, preferring a config, lint, or permission change over a prose instruction when both could enforce the behavior.

### 4. Discuss

Present a short discussion: numbered proposals (what to change, the target file per Proposal targets, why, one line of evidence each), then a one-line rejected list. Wait for the user; they may redirect a proposal's scope (skill vs global rule vs model-specific). Apply only what they approve, then remind them to run `task cs` and restart opencode so skill and config changes load.

## Proposal targets

Reviewers propose a routing per finding; confirm or redirect it during synthesis, and the user has final say in the discussion.

- `.config/opencode/skills/<name>/SKILL.md` (or a new skill) - triggerable procedure; the common case
- `.config/opencode/models-md/<model-or-family>.md` - a correction only one model or family needs. Filenames match the active provider/model by hyphen-boundary prefix (claude.md covers all claude-*; see plugins/models-md.ts). Reserve for behavior seen repeatedly; one bad session is weak evidence.
- `.config/opencode/AGENTS.md` - a rule every model in every session follows
- `.config/opencode/opencode.json` - permissions or tooling structure; prefer a setting over prose when both can enforce the behavior
- the session project's own `.opencode/skills/` or AGENTS.md - the learning is specific to that codebase, not global
