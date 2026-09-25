---
description: Use when the user says "morning", "good morning", "start my day", or asks for a daily kickoff or orientation on the day's work. A conversation that organizes the day — sets up today's Obsidian daily note, discusses carryover and new tasks, then on-demand dives into tracked items and the GitHub work queue.
name: morning
---

# Morning

Organize the user's day via a conversation. Task tracking lives in
the user's Obsidian vault — the skill reads it, writes new tasks where they
belong, and keeps the conversation on what changed, never on the routine. The
deeper stuff (tracked items, GitHub) takes real time to gather, so it's offered
as dives they choose, never assumed. After every dive, check in on what's next.

This skill is a deliberate exception to the usual terse house style. Write like a colleague giving a
morning briefing: conversational, plainspoken, still grounded and specific. The "Good Morning 🌅"
greeting is the one flourish — after that, skip the hollow stuff: exclamation marks, further emoji,
"hope this finds you well".

## Step 1: Set up the daily note

The vault is the opencode project root — this skill runs from there, and vault
files are referenced relative to it: `To Do/Routines.md`, `To Do/Tasks.md`,
`To Do/Goals.md`, `To Do/TRACKING.md`, `Daily/YYYY-MM-DD.md`. Compute today's
date first — everything below needs it.

- `To Do/Routines.md` — recurring tasks, one per line. Each carries `🔁 <rule>` and a
  `🛫 YYYY-MM-DD` scheduled date; the Tasks plugin creates the next occurrence
  when the user checks the box. Never edit these lines except at the user's
  explicit request.
- `To Do/Tasks.md` — one-time tasks, grouped by area headings. `⏫` marks urgent
  items that must surface every day. `📅 YYYY-MM-DD` is a due date. Indented
  non-checkbox lines under a task are notes, not tasks.
- `To Do/Goals.md` — the longer arc. Read for context; never recite it in
  conversation.
- `Daily/YYYY-MM-DD.md` — daily notes, one per day, created from the Obsidian
  template `Templates/Daily note.md` (wired up in `.obsidian/daily-notes.json`).
  If today's note doesn't exist, create it from that template right away,
  before talking — if the session dies, the note exists. If it does exist,
  leave it alone. Task conventions and Tasks-query guidance live in AGENTS.md.

## Step 2: Open the conversation

Open with "Good Morning 🌅" and a single plain line — day and date. Then run
carryover: scan `To Do/Tasks.md` for unchecked tasks whose `📅` date is before today.
Present each briefly and ask whether to do it today, keep it (set `📅` to
today), or drop it. If none, skip silently.

Then ask what else is on today's list. First surface anything dated: tasks in `To Do/Tasks.md` with a `📅`
due within the next 14 days, with countdowns ("due Friday", "3 days left", "overdue 2 days")
computed against today. Then fold their answers into the vault as they're agreed, not at the end:

- **Recurring** (they state a cadence) — append to `To Do/Routines.md`:
  `- [ ] {text} 🔁 {rule} 🛫 {next occurrence}`. Rules: `every day`,
  `every week on Mon, Wed, Fri`, `every month`, `every 3 days`. The scheduled
  date is required — recurrence is generated from it on completion.
- **One-time with a date** — append to `To Do/Tasks.md` under the matching area
  heading with `📅 {date}`.
- **Ad-hoc for today** — append to `To Do/Tasks.md` with `📅 {today}` so it shows
  today and carries over as overdue if unchecked.

Task text stays 3–12 words, plain. Add metadata only when the cadence or date
was stated; ask rather than guess. Reschedule by editing the `📅` date; delete
by removing the line. Leave checking boxes off to the user in Obsidian unless
they ask.

## Step 3: Offer the dives

Present the options and let them choose:

- **Tracked items** — what moved on the things followed in `To Do/TRACKING.md`
- **GitHub** — assigned issues, PRs waiting on their review, their own PRs
- Or neither — the day's organized already

If they pick both, launch both subagents in one message.

## Step 4: Run dives on request

For each dive, launch a `task` call with `subagent_type: general` and the prompt
below, filling in today's date where marked. Present the report per that dive's
format. When a dive is complete, ask what's next — another dive, additions to
the day's list, or done.

### Subagent A: tracked items

```text
Read `To Do/TRACKING.md` in the Obsidian vault at the project root. Check every
row in the "Following" table —
skip the other sections. Resolve each row's link from the reference definitions at
the bottom of the file, get its current state with `gh` (gh issue view / gh pr view
as appropriate) or a web fetch, and compare against the row's Status column.

Then edit `To Do/TRACKING.md`: update Status where the state changed, and set Last checked
to {DATE} on every row you checked, changed or not. Preserve the table format.

Return in your final message, for every row: the item ID, the Description verbatim
from the table, whether its state changed, what changed if so, and its URL. Flag
anything you couldn't check, with the reason.
```

Present every tracked item as a row in a Markdown table: the item (ID and
description), its current status, and a short note on what changed — "no change"
where nothing moved. Keep URLs out of the table. Below the table, list the links
for the items that warrant attention today — the ones that moved or need a
decision. If nothing moved anywhere, say so plainly.

### Subagent B: GitHub work queue

```text
Assemble the user's GitHub work queue, scoped to @me across orgs. Two parts.

Assigned issues: open issues assigned to the user, via `gh search issues
--assignee:@me --state:open`. Group by repo, return title and URL for each.

PR inbox: use `gh search prs` and `gh pr view` (fields: statusCheckRollup,
reviewDecision, mergeable, mergeStateStatus). Group by org — liatrio, driftkeylabs,
personal repos, and so on. Sort into:

1. Needs the user's review — human-authored (exclude bots), open, review requested
   from the user. Drop any with failing CI checks and report how many were dropped.
2. The user's PRs awaiting team review — authored by the user, review not yet
   resolved.
3. The user's PRs blocked — authored by the user, with failing CI, merge conflicts,
   or changes requested. State the specific reason for each.
4. Bot-authored review requests — one count per org, no per-PR list.

Return both parts with the URL for everything, grouped as specified.
```

Lead with assigned issues — the work queued for them — as a compact list grouped
by repo. Then walk the PR inbox categories in order, grouped by org, as a compact
list with links — category 4 as a one-line count per org.

## Step 5: Close with a recommendation

When the user is done diving, close with a real recommendation: given the
day's list, whatever the dives surfaced, and the goals in `To Do/Goals.md`, the one or
two things worth starting with today, and why. One or two sentences, honest. If
nothing needs attention, say the day is clear and mean it.

Then write it all into today's daily note — the only conversation outputs that
go there:

- **From the discussion** — the important points from the conversation as short
  bullets (2–6; things worth remembering later, not a transcript)
- **Recommendation** — the closing recommendation verbatim

If the note already has these sections filled from an earlier run today, merge
rather than duplicate. If a subagent came back empty or partial, say so plainly
rather than papering over the gap.
