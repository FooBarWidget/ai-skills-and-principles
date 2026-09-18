---
name: documentation-principles
description: Use when writing or reviewing documentation
---

## Documentation principles

- Use natural, direct, plain English. Prefer concrete subjects and actions. Avoid canned introductions and inflated claims. Use sentence case for headings. Do not cap line widths.
- For internal developer documentation:
  - Write for a capable developer who is new to this codebase. Explain purpose or constraints before implementation details. Introduce technical terms before using them densely. Use examples when they explain behavior more quickly than explanation alone.
  - Keep information that helps readers understand a non-obvious design, find where to make a change, make a decision, or avoid a mistake. Leave implementation details, exhaustive behavior and minor edge cases to the code and tests when they are easily recovered there.
- Keep user documentation focused on public setup, behavior, and limitations. Omit internals and exhaustive behavior.
- Organize content around distinct information readers need, not a repeated template. Add a section only when it contains substantial, distinct information. Avoid routinely giving every topic matching sections such as "What it is"/"Why it matters"/"How it works". Integrate short explanations of purpose or rationale into the relevant paragraph.
- Use headings to help readers navigate distinct topics without fragmenting closely related material. Use conclusions to synthesize long or complex documents, not merely repeat earlier content.
- Before finalizing, remove anything that does not materially aid understanding. Avoid repeating information that an example or an earlier section already makes clear.
