---
name: documentation-principles
description: Use when writing or reviewing documentation, including code comments
metadata:
  dependencies: escalation-policy
---

## Documentation principles

Apply these principles as relevant to the artifact.

Language, style, and formatting:

- Use natural, direct, plain English. Avoid canned introductions and inflated claims. Use sentence case for headings.
- Do not cap line widths. For code comments, follow repository wrapping conventions.
- Prefer concrete subjects, precise verbs, and active voice. Use passive voice when the actor is unknown, irrelevant, or less useful as the focus.

Audience, purpose, and information flow:

- Use Diátaxis philosophy as guidance for reader needs: action vs understanding, learning vs application. Give each document or coherent group of sections a clear purpose; preserve it when revising. Distinguish different purposes through sections or transitions where useful.
- Lead with the main point relevant to the reader's current question. Build from what readers already know; introduce unfamiliar concepts and technical detail when their relevance is clear.
- Make relationships between ideas explicit. State the organizing idea before examples or cases, and connect shifts in purpose or scope. Keep the intended reader and references to people or things clear.
- Infer intent and rationale when reasonably supported by context. Apply the escalation policy to unresolved gaps or uncertainty, considering confidence and consequences of being wrong.

Document structure:

- Organize around distinct reader needs. Reuse consistent patterns for comparable entries; avoid forcing every topic into matching sections like "What it is"/"Why it matters"/"How it works". Add a section only when separating distinct information helps readers navigate or understand it. Integrate brief explanations of purpose or rationale into relevant paragraphs.
- Use headings to mark meaningful changes in topic or purpose without fragmenting closely related material. Make each heading accurately describe the material beneath it.
- Split at distinct purposes or major topics (subjects readers seek independently) only when separate documents materially improve understanding or navigation, or readers naturally expect them. Each resulting document should have enough substance and a clear standalone purpose; regroup small remnants with related material.
- Merge short documents when they serve closely related reader needs and separation adds navigation overhead without useful independence. Preserve meaningful distinctions through sections.
- Use conclusions to synthesize long or complex documents, not merely repeat earlier content.

Concision and revision:

- Be concise by removing repetition and unnecessary detail while preserving connections, qualifications, and distinctions needed for understanding. Split sentences or paragraphs when compression makes them dense.
- Before finalizing, remove material that serves no useful reader purpose. Avoid repeating information already clear from an example or earlier section unless repetition helps readers navigate, connect ideas, or act.

For internal developer documentation:

- Write for a capable developer who is new to this codebase. Explain purpose or constraints before implementation details. Briefly introduce potentially unfamiliar technical terms and concepts before using them densely, judging familiarity from the reader's likely background. Use examples when they explain behavior more quickly than explanation alone.
- For standalone docs:
  - Keep information that helps readers understand a non-obvious design, find where to make a change, make a decision, or avoid a mistake.
  - Leave implementation details, exhaustive behavior and minor edge cases to the code and tests when they are easily recovered there.

For user documentation:

- Focus on public setup, usage, behavior, and limitations.
- Include details needed for correct use or troubleshooting. Include edge cases only when likely reader needs or consequences of misunderstanding justify the detail; keep them from obscuring the main point. Omit internals unless they serve those needs.
