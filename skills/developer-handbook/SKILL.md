---
name: developer-handbook
description: |
  About the developer handbook: purpose, content, writing guidelines. Use when coding. Use when updating internal developer documentation, or reviewing it against guidelines.
---

## Developer handbook

The handbook is a series of Markdown files in `devdocs/`. Purposes of the handbook:

- Teaches a capable human or AI developer, who does not know this codebase, how this codebase works so that they can contribute effectively. For AI, the handbook functions as a series of skills, with an index functioning as a skill router.
- Documents important design decisions, rationale and constraints so they don't get lost or become implicit.

Content coverage:

- Overall architecture and/or flow
- Important concepts and constraints
- Important design patterns where non-obvious
- Important or non-obvious design decisions
- Important subsystems

Writing guidelines:

- Use the documentation principles.
- Use `devdocs/README.md` as a concise, keyword-rich topic index and skill router.
- Give each major topic one canonical document and each document one primary topic.
  - A topic is major when changing it safely requires a distinct mental model because it has its own concepts, constraints, failure modes, platform behavior, or reasons to change. Code-module boundaries alone do not determine document boundaries.
- When writing an Architecture document, keep it as a map of components, main flows, and system-wide constraints. Summarize and link to canonical topic documents instead of putting subsystem details there.
- At topic boundaries, explain only the local interaction and link to the canonical document. Do not duplicate the complete policy.
- Document important rationale and non-obvious design decisions. Omit trivial information and content already covered by user documentation, `AGENTS.md`, or `CONTRIBUTING.md`.
- Must reflect current behavior rather than idealized goal. If they differ, document the divergence.

Update the handbook in the same change when architecture, flows, major concepts, constraints, patterns, decisions, or subsystems change.
