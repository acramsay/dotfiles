---
name: code-review
description: Review a pull request (URL or number) or the changes since a fixed point (commit, branch, tag, merge-base) along two axes — Standards (does the code follow this repo's documented coding standards?) and Spec (does the code do what the PR/issue asked for?). Runs both reviews in parallel sub-agents, reports them side by side, and offers to post the result to the PR as a review. Use when the user wants to review a PR, a branch, work-in-progress changes, or asks to "review since X".
---

Two-axis review of a pull request, or of the diff between `HEAD` and a fixed point:

- **Standards**: does the code conform to this repo's documented coding standards?
- **Spec**: does the code faithfully implement what the PR / originating issue asked for?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings.

## Process

### 1. Get the diff

The user will normally supply a **PR URL or number**. Work read-only: leave the working tree, index, and HEAD untouched.

Use the forge tooling available for the PR's host — `gh` for GitHub, `glab` for GitLab, a forge MCP server or API token if configured — to:

- Fetch metadata once: title, body, base/head refs, commit list, and linked/closing issues (on GitHub: `gh pr view <pr> --json title,body,url,baseRefName,headRefName,commits,closingIssuesReferences`)
- Fetch the diff itself (on GitHub: `gh pr diff <pr>`)

Keep the title, body, and linked issues aside for step 2. If no forge tool can reach the PR's host, ask the user how to get the diff rather than improvising git remote plumbing.

If the user instead supplies a **fixed point** (commit SHA, branch, tag, `main`, `HEAD~5`):

- Capture `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base) and the commit list via `git log <fixed-point>..HEAD --oneline`.
- Confirm the fixed point resolves (`git rev-parse <fixed-point>`).

Either way, confirm the diff is non-empty before going further. An unknown PR, bad ref, or empty diff should fail here, not inside two parallel sub-agents.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. **The PR itself**: title and body from step 1, plus its linked issues (closing issues and `Fixes #123`-style references in the body), fetched with the forge tool (on GitHub: `gh issue view <n>`).
2. Issue references in the commit messages, fetched the same way.
3. A path the user passed as an argument.
4. A spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name or feature.
5. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below: a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name**: a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn both sub-agents in parallel

Sub-agents don't see this skill, so each prompt must be self-contained. Both briefs should also carry: "If the diff leans on external libraries, APIs, or domain context you can't confidently evaluate from the repo alone, use the `research` skill to fill the gap before judging — don't guess, and say what you verified versus assumed."

**Standards sub-agent prompt** should include:

- How to get the diff: the exact command you used in step 1 (forge or git), plus the commit list, so the sub-agent can re-run it.
- The list of standards-source files you found in step 3, **plus the smell baseline from step 3** pasted in full (the sub-agent has no other access to it).
- The brief: "Report, per file/hunk where relevant, (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls: documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** should include:

- How to get the diff, as above.
- The fetched spec contents: PR title and body, linked issue text, or the spec file path.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings, because the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes: that's the reranking the separation exists to prevent.

### 6. Offer to post the review to the PR

Skip this step when the target was a local fixed point rather than a PR.

The user sees the findings first: the report is already presented in step 5. Ask whether to post it to the PR, and post only after the user confirms.

Shape the posted review the way a human reviewer would write it:

- The review body is a short top-level summary — the per-axis totals and worst issues from step 5 — not the full report.
- Each finding goes up as its own inline comment anchored to the specific file and line it concerns. On GitHub that's a single review created with `gh api repos/{owner}/{repo}/pulls/{n}/reviews` carrying a `comments` array of `{path, line, body}` entries, where `line` is a line in the PR diff.
- Findings that attach to no specific line (missing tests, spec gaps, scope creep) belong in the review body after the summary.
- Write in the voice of a human reviewer and run all posted prose through the `unslop` skill first — the review is human-facing writing.
- Default to a comment review. Approve or request changes only when the user asked for that verdict.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
