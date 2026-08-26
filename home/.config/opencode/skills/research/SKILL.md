---
name: research
description: Research an external topic (products, technologies, tools, APIs, services) with parallel web-research subagents, then report the synthesized answer with cited links. Use when the user asks to research, compare, evaluate, or find out about something outside the codebase — "research X", "compare X vs Y", "should I buy X", "is X worth using".
---

# Research

Investigate the question with parallel subagents, then deliver the synthesized answer in the
conversation with links to sources. The deliverable is the answer itself, in chat — persist
nothing to disk unless the user asks.

## Process

1. **Scale effort to the question.**
   - Simple lookup or fact-check: answer directly with a search or two, no subagents.
   - Product pick or head-to-head comparison: 2–4 subagents.
   - Multi-faceted evaluation or broad landscape: 3–5 subagents.

2. **Decompose into non-overlapping subtopics.** Give each subagent a distinct angle so no two
   run the same searches. For a product: candidates, specs, price, owner feedback. For a
   technology: what it is and how it works, maturity and adoption, alternatives and tradeoffs,
   getting started.

3. **Fan out.** Spawn one subagent per subtopic, all in parallel rather than sequentially.
   Each subagent's brief states its specific question, its budget (~3–5 searches), and the
   source discipline:
   - Prefer **primary sources** — official docs, manufacturer and vendor pages, specs, source
     code, first-party APIs — over secondary write-ups. Follow every claim back to the source
     that owns it.
   - Start with broad queries, then narrow based on what surfaces.
   - Return key facts, each with its source URL, plus uncertainties and conflicting evidence.

4. **Synthesize in conversation.** Lead with the direct answer, then the analysis the user
   asked for. Attach a source link to each factual claim. Surface disagreements between
   sources and open questions rather than smoothing them over.

## Output shape

- Direct answer first, then supporting analysis.
- Links inline, next to the claims they support.
- A short "Open questions" section when anything material stayed uncertain.
