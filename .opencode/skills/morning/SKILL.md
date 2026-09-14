---
name: morning
description: Use when the user says "morning", "good morning", "start my day", or asks for a daily kickoff or orientation on the day's work. A conversation that organizes the day — today's plan up front, then on-demand dives into tracked items and the GitHub work queue.
---

# Morning

Organize the user's day as a conversation, not a script. Open with what's instant to gather — today's declared plan, then whatever else is on their mind. The deeper stuff (tracked items, GitHub) takes real time to gather, so it's offered as dives they choose, never assumed. After every dive, check in on what's next.

This skill is a deliberate exception to the usual terse house style. Write like a colleague giving a morning briefing: conversational, plainspoken, still grounded and specific. The "Good Morning 🌅" greeting is the one flourish — after that, skip the hollow stuff: exclamation marks, further emoji, "hope this finds you well".

## Step 1: Open with the day plan

Read `~/.config/morning/plan.md`. It's a Markdown table of repeatable items; the
file is gitignored and machine-local, so absence is normal — skip it silently.
The `When` column holds day names (`Mon`, `Mon,Wed,Fri`), exact dates
(`2026-09-18`), or a day/date plus a time in free text — keep time and note text
verbatim when filtering. Filter to rows whose `When` matches today, by day name
or exact date.

Open with "Good Morning 🌅" and a single plain line — day and date. Present
today's rows as a short list, task and time. If no rows match, say there's
nothing declared for today and move straight on.

Then ask what else is on today's list. The day's list lives in the conversation,
not a file — fold their answers in as plain items. If they mention something
repeatable, offer to add it to the plan file.

## Step 2: Offer the dives

Present the options and let them choose:

- **Tracked items** — what moved on the things followed in TRACKING.md
- **GitHub** — assigned issues, PRs waiting on their review, their own PRs
- Or neither — the day's organized already

If they pick both, launch both subagents in one message.

## Step 3: Run dives on request

For each dive, launch a `task` call with `subagent_type: general` and the prompt
below, filling in today's date where marked. Present the report per that dive's
format. When a dive is complete, ask what's next — another dive, additions to
the day's list, or done.

### Subagent A: tracked items

```
Read TRACKING.md at this repo's root. Check every row in the "Following" table —
skip the other sections. Resolve each row's link from the reference definitions at
the bottom of the file, get its current state with `gh` (gh issue view / gh pr view
as appropriate) or a web fetch, and compare against the row's Status column.

Then edit TRACKING.md: update Status where the state changed, and set Last checked
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

```
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

## Step 4: Close with a recommendation

When the user is done diving, close with a real recommendation: given the day's
list and whatever the dives surfaced, the one or two things worth starting with
today, and why. One or two sentences, honest. If nothing needs attention, say
the day is clear and mean it.

If a subagent came back empty or partial, say so plainly rather than papering
over the gap.
