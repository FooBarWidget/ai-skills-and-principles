---
name: changelog-guidelines
description: Guidelines for writing changelogs. Use when writing changelogs, or reviewing against guidelines.
---

## Changelog guidelines

Write changelog entries for users. Apply the documentation principles (treat changelog entries as user documentation), but optimize specifically for quickly communicating the user-visible impact of a change.

Describe what changed from the user's perspective: what they can now do, what behaves differently, or what problem is fixed. Prefer the observable behavior or outcome over implementation details, internal architecture, or developer rationale.

Keep entries short. Usually use a single sentence; add more only when users need additional information to understand the impact, a limitation, or an action they must take.

Include conditions or affected scenarios when they help users determine whether the change matters to them. Make breaking changes, changed defaults, compatibility implications, or required user action explicit.

For bug fixes, describe the user-visible problem that was fixed rather than its internal cause. For improvements, state the concrete improvement rather than making generic claims such as "improved performance" or "improved reliability" when the actual effect can be stated more precisely.

Avoid including implementation mechanics, files or symbols changed, tests, internal design decisions, or review context unless they are directly relevant to how users interact with the product.

If a change has no meaningful user-visible effect, normally do not add a changelog entry.
