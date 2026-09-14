# Listing opencode plugins in community directories

Process for listing an opencode plugin in the three community sources, in priority
order. Distilled from listing shield-bash (Sep 2026) — see the worked-example PRs in
TRACKING.md "Following". Re-verify conventions before each run; these repos change.

Prerequisite: the plugin must be published to npm first. All three sources reference
the npm package, and maintainers check that it installs.

## Common workflow

- Fork + shallow clone: `gh repo fork <upstream> --clone --depth 1`, feature branch,
  edit, push, **draft** PR. Convert to ready manually after review.
- Research before editing: read CONTRIBUTING.md, the PR template, and 2–3 recent
  merged PRs that added entries. Format, ordering, and title conventions come from
  precedent, not guesswork.
- Use one description across all three sources, adapting only for hard length caps.
- Verify locally before pushing: run the target repo's validator if it has one,
  `jq` for JSON, and check table padding by eye.
- On PR branches, never amend or force-push already-pushed commits — add new commits.
  Beware "Update branch" merges of upstream appearing on the branch (via the GitHub
  UI); cherry-pick your next commit on top of the merge instead of force-pushing.
- Add the PRs to TRACKING.md "Following" with status `draft`.

## 1. Official ecosystem docs — opencode.ai/docs/ecosystem

The closest thing to an official registry. Source: `packages/web/src/content/docs/
ecosystem.mdx` in anomalyco/opencode (the page's "Edit page" link finds it).

- One row in the Plugins table: `| [npm-name](github-repo-url) | description |`.
  Name is the npm package name (scoped names stay scoped) and links to the GitHub
  repo. Append at the end of the table — both are settled precedent.
- The table is hand-padded: both cells padded to 100 display chars so the pipes
  align. Keep the description at 100 chars or fewer; longer rows break alignment and
  invite a noisy re-padding diff.
- Title must be a conventional commit (`docs(ecosystem): add <name> plugin`) — a bot
  enforces it. The issue-first policy is skipped for `docs:` PRs; answer the template's
  issue section "N/A — documentation addition".
- The PR body must fill their template exactly. A compliance bot labels non-compliant
  PRs and **auto-closes them after 2 hours** — check the PR right after opening.
- No DCO/sign-off. No locale copies of the page to update.

## 2. awesome-opencode — awesome-opencode/awesome-opencode

The list is generated, not hand-edited.

- Entries are YAML files under `data/plugins/` (schema: `data/schema.json`). Required:
  `name`, `repo`, `tagline` (**max 120 chars**, shown collapsed), `description`
  (shown expanded). Optional: `scope`, `tags`, `min_version`, `homepage`,
  `installation`. Add `homepage` pointing at the npm package page.
- **Never edit README.md** — `scripts/generate-readme.js` regenerates it on merge,
  sorting alphabetically. Ordering needs no thought.
- Run `node scripts/validate.js data/plugins/<file>.yaml` before pushing; CI runs it
  on changed YAMLs.
- Eligibility (echoed as a PR checklist): relevant, public, maintained (commits
  within 6 months), unique, complete. No star-count bar, no issue-first requirement.
- Commit/PR style: `docs: add <name> to plugins`.

## 3. opencode.cafe — R44VC0RP/opencode.cafe

Community marketplace (Next.js + Convex + Clerk), not affiliated with opencode.
Weakest link: no bulk PR has ever been merged as of Sep 2026 — watch how the
shield-bash PR resolves before relying on this path.

- Two submission paths, both landing in an admin review queue as `pending`:
  1. PR appending to `bulk/plugins.json` (admins bulk-import via their dashboard).
  2. Web form at opencode.cafe/submit (Clerk login).
- Entry fields: `productId` (lowercase letters/hyphens, `^[a-z][a-z-]*[a-z]$`),
  `type` `"plugin"`, `displayName`, `description` (one line; observed range 85–166
  chars), `repoUrl`, optional `homepageUrl`, `tags` (lowercase, 4–6, inline array),
  `installation` (markdown starting with `## Installation`). Append at the end of the
  array.
- No CI validation — check the JSON with `jq` yourself.
- Put prerequisite config in `installation` (e.g. judge model config for shield-bash),
  not just the install command; reviewers flagged a prior PR for that.

## Open questions

- Whether opencode.cafe prefers the bulk PR or the web form (asked in the shield-bash
  PR; unresolved).
