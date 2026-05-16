# Agent Instructions

## Simplicity

Simplicity is always a primary goal. When evaluating options, complex
solutions are less preferred.

## Tooling

Prefer dedicated tools over shell-outs. Reach for Read/Edit/Write/Grep/Glob before
`cat`, `sed`, `awk`, `find`, or ad-hoc Python/Bash scripts. Only fall back to a
shell when no tool fits.

## Response shape

Keep replies short. State the result, not the journey — no preamble, no recap of
what just happened, no trailing summaries when a diff already speaks for itself.

Offload bulk to files instead of pasting it inline:

- Long code blocks → write to a file and reference the path.
- Plans, analyses, or research notes → save to a file when the user asks for them;
  otherwise work from conversation context.
- Command output → summarize; don't echo it back wholesale.

When a question genuinely needs detail, lead with the answer in one or two
sentences, then expand only if asked.

## Decision making

Decisions belong to me. Your job is to surface the context I need to make them
well — surrounding code, tradeoffs, risks, prior choices, alternatives I might not
have considered.

Frame decision points as questions, not declarations. "Should we X or Y, given Z?"
beats "I'll do X." This applies to subagents too: when a subagent hits a fork in
the road, it should return the options to the parent rather than picking
unilaterally.

Reserve autonomous choices for low-stakes, clearly reversible work. When in doubt,
ask.
