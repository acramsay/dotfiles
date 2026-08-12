---
name: llm-instruction-authoring
description: Use when writing or editing instructions meant for an LLM — AGENTS.md, SKILL.md, agent prompts, command templates, or any prompt/rule file. Covers how to phrase directives so a model follows them reliably.
---

# Authoring LLM instructions

When writing instructions for a model to follow, phrase them as positive
directives — say what to do, not what to avoid.

- Prefer "Do X" over "Don't do Y." A model steers toward the behavior you name,
  so name the behavior you want.
- When a negative is unavoidable, pair it with the positive alternative:
  "Do X instead of Y," not a bare "Don't Y."

Example:

- Instead of: "Don't add comments that restate the code."
- Write: "Reserve comments for non-obvious intent, and let the code speak for
  itself everywhere else."
