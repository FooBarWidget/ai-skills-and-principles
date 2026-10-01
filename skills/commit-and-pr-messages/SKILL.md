---
name: commit-and-pr-messages
description: Use when writing or reviewing commit and PR messages, to help human reviewers understand and assess changes.
metadata:
  dependencies: documentation-principles, escalation-policy
---

## Version control commit and pull request messages principles

Write version control commit and PR messages for human reviewers. Apply the documentation principles (treat commit/PR messages as internal developer docs), but optimize specifically for reducing the mental effort needed to understand and review the diff. Consider commit and PR messages to be the same, because they are, due to usage of squash commits.

Describe changes at the level of intent, behavior, and design rather than code mechanics. Ground inferred intent and design in the request, conversation, tests, relevant repository history, and contrast with previous behavior. Do not invent unsupported motivation or put unresolved uncertainty about intent into the message. When intent is materially unclear, inspect related history; if focused research does not resolve an ambiguity that could materially change the message, ask focused questions. Otherwise, write the best grounded message available.

Scale the explanation to the review burden. For large or conceptually broad diffs, start with enough high-level context to orient the reviewer: what the change does, how the main parts fit together, and what to expect. This is useful even when it could eventually be inferred from the diff. For small, self-explanatory diffs, avoid a redundant summary unless there is useful non-obvious context.

Include non-obvious information that materially helps review, such as the prior problem or motivation, design decisions and rationale, research findings or constraints, tradeoffs, caveats, consequences, meaningful validation or rollout information, and areas deserving particular attention. Do not treat this as a checklist or invent significance to fill it.

Avoid narrating the diff, enumerating obvious edits, and adding generic claims or filler. Mention implementation details, files, or symbols only when they materially help review; make their relevance clear.

Avoid standalone verification sections and test-run checklists. Integrate material validation findings or gaps into the relevant explanation.

For titles, concisely name the specific change or outcome; avoid vague labels like "Misc fixes".

For bodies, provide enough orientation and context to make review easier, but no more. Avoid rigid templates and unnecessary sections.
