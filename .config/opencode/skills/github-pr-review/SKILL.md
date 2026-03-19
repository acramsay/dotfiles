---
name: github-pr-review
description: Review GitHub pull requests using the gh CLI tool
license: MIT
compatibility: opencode
metadata:
  category: code-review
  tools: gh, bash
---

## What I do

I help you review GitHub pull requests using the `gh` CLI tool. I provide a structured summary that includes:

1. **PR Purpose**: Description of what the PR is trying to accomplish
2. **Purpose Evaluation**: Whether the changes fully address the stated purpose
3. **Discussion Status**: Summary of comments awaiting developer response
4. **Attention Required**: Discussion comments that need YOUR input as reviewer
5. **Problems Discovered**: Issues found in the code changes
6. **Quality Score**: A 0-10 score reflecting confidence in PR quality

Intermediate analysis steps are hidden; only the final summary is displayed.

**Security constraints:**
- Read operations (viewing PRs, diffs, comments) are allowed automatically
- Write operations (commenting, approving, requesting changes) require explicit confirmation
- Only `gh pr view`, `gh pr diff`, `gh pr list`, `gh pr comment`, and `gh pr review` commands are permitted
- All other `gh` commands are blocked

**Discussion review:**
- I automatically fetch and analyze existing PR comments/discussions
- I consider all existing feedback when providing my review
- I do NOT respond to or address specific comments directly
- **Attention Required** items are only comments that need YOUR input as the reviewer
- Comments awaiting developer response are noted separately but do not trigger "Attention Required"

**Streamlined output:**
- Intermediate analysis steps (thinking, file parsing, etc.) are hidden from view
- Only the final structured summary is displayed
- Command output is shown only when necessary for context

**Summary format:**
- **PR Purpose**: Description of what the PR is trying to accomplish
- **Purpose Evaluation**: Whether the changes fully address the stated purpose
- **Discussion Status**: Summary of comments awaiting developer response
- **Attention Required**: Discussion comments that need YOUR input as reviewer
- **Problems Discovered**: Issues found in the code changes
- **Quality Score**: 0-10 rating (8.0+ = quality PR needing little attention, <2.0 = abandon and restart)

**Quality scoring factors:**
- Scope: Narrower scope scores higher
- Size: Fewer changed lines score higher
- Complexity: Simpler changes score higher
- Completeness: Fully addressing purpose scores higher

## When to use me

Use this skill when you need to:

- Review a specific pull request
- Understand what changes a PR introduces
- Check CI/CD status and review comments
- Analyze code quality before merging

**Before using me**, make sure you have:

1. `gh` CLI installed: `brew install gh` (or equivalent for your OS)
2. Authenticated with GitHub: `gh auth login`
3. Access to the repository you're reviewing

## How to use me

### Basic PR review

Ask me to review a specific PR:

```
Review PR #42 in this repository
```

```
Look at https://github.com/owner/repo/pull/123
```

### Review with focus

Ask me to focus on specific aspects:

```
Review PR #42 and check for security issues
```

```
Review PR #123 and focus on performance and readability
```

### Fetch PR details

Ask for general information:

```
What's the status of PR #42?
```

```
Show me the changes in PR #123
```

## Available commands

I can execute these `gh` commands via bash. Read operations are automatic; write operations require confirmation.

### Read operations (automatic)
**Get PR information**
```bash
gh pr view <PR-NUMBER> --json title,author,state,createdAt,reviewDecision,mergeable,additions,deletions,url
```

**Get PR files**
```bash
gh pr view <PR-NUMBER> --json files
```

**Get PR diff**
```bash
gh pr diff <PR-NUMBER>
```

**Get PR comments**
```bash
gh pr view <PR-NUMBER> --json comments
```
*Used to analyze existing discussion before reviewing*

**List recent PRs**
```bash
gh pr list --limit 10 --json number,title,author,state,createdAt
```

### Summary generation process
1. **Fetch PR details**: Understand the stated purpose from title/description
2. **Fetch existing comments**: Identify any discussion that needs attention
3. **Fetch code changes**: Analyze diffs to understand what was modified
4. **Evaluate purpose**: Determine if changes fully address the PR's goal
5. **Identify problems**: Check for security, performance, and style issues
6. **Compile summary**: Present findings in the structured format

### Write operations (require explicit approval)
**Add a comment to a PR**
```bash
gh pr comment <PR-NUMBER> --body "<your comment>"
```
*Requires: User confirmation before execution*

**Approve a PR**
```bash
gh pr review <PR-NUMBER> --approve
```
*Requires: User confirmation before execution*

**Request changes on a PR**
```bash
gh pr review <PR-NUMBER> --request-changes --body "<your feedback>"
```
*Requires: User confirmation before execution*

## Confirmation flow for write operations

When you ask me to perform a write operation (comment, approve, request changes), I will:

1. Show you the exact command I'm about to run
2. Ask for explicit confirmation
3. Only execute the command after you approve

Example:
```
User: Add a comment to PR #42 saying "Looks good to me!"
Assistant: I will add the following comment to PR #42:
          "Looks good to me!"
          
          Command: gh pr comment 42 --body "Looks good to me!"
          
          Confirm execution? (yes/no)
```

## Example workflow

1. **Fetch PR details** (automatic):
   ```
   gh pr view 42 --json title,author,state,reviewDecision,url
   ```

2. **Fetch existing comments/discussion** (automatic):
   ```
   gh pr view 42 --json comments
   ```
   *I will analyze any existing feedback before reviewing*

3. **Review the code changes** (automatic):
   ```
   gh pr diff 42
   ```

4. **Generate and display structured summary**:
   - **PR Purpose**: [description of what the PR aims to do]
   - **Purpose Evaluation**: [assessment of whether changes fully address the purpose]
   - **Discussion Status**: [summary of comments awaiting developer response]
   - **Attention Required**: [discussion comments that need YOUR input]
   - **Problems Discovered**: [issues found in the code]
   - **Quality Score**: [0-10 rating based on scope, size, complexity]

5. **Add a comment** (requires confirmation):
   ```
   User: Add a comment to PR #42
   Assistant: [shows command, asks for confirmation]
   User: yes
   Assistant: [executes command]
   ```

## Tips

- Reference the PR URL directly in conversations
- Use `gh pr view` to get current status before reviewing
- Check review decisions and CI status before approving
- Use `gh pr diff` to see actual code changes
- The agent can combine this skill with file reading for deeper analysis
- Write operations (comments, approvals) require explicit confirmation for security
- Only `gh pr view`, `gh pr diff`, `gh pr list`, `gh pr comment`, and `gh pr review` commands are permitted
- Summary format focuses your attention on what matters most: purpose, evaluation, discussion status, attention items, problems, and quality score
- Discussion Status shows comments awaiting developer response (not your attention)
- Quality score: 8.0+ = quality PR needing little attention, <2.0 = abandon and restart
