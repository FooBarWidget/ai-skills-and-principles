---
name: coding-guidelines
description: Use when writing code, or reviewing against guidelines
metadata:
  optional-dependencies: documentation-principles # when writing comments
---

## Coding guidelines

- Prefer boring, explicit code over cleverness or premature abstraction. Keep the main code path easy to follow and centered on business logic; move incidental technical or secondary details into helpers when they obscure that flow. Some duplication is fine. Extract shared abstractions only when they clearly improve readability or eliminate substantial duplication, and avoid speculative generalization.
- Surgical changes:
  - Keep changes tightly scoped to the requested outcome. Avoid unrelated cleanup, refactoring, formatting, or stylistic changes.
  - Make low-impact refactorings autonomously when needed for a clean implementation or readability, and remove code made obsolete by the change. Follow existing project conventions unless there is a good reason not to.
  - Leave unrelated pre-existing issues unchanged. Report material ones without blocking the requested work.
- Proper error handling
  - Shell scripts: use pipefail
  - When ignoring errors, only ignore specific errors, not blanket ignore all errors
- Commenting strategy:
  - Apply the documentation principles, treating comments as internal developer docs. Assume reader may also be new to the subsystem or platform.
  - Comment non-obvious context the code cannot express clearly: purpose, domain terms, responsibilities, input/output semantics, algorithm stages, invariants, caveats, decisions. Explain complicated algorithms at a high level to aid human understanding. Concisely state non-obvious class, module, or method responsibilities. Avoid narrating straightforward code.
  - Use precise technical terms where useful. Explain how introduced concepts relate to nearby code; do not make readers derive their meaning from mechanics or call sites.
  - Keep comments concise and place them where they apply. Put broader or cross-cutting rationale/caveats in the developer handbook, retaining essential context locally and linking where useful.
- Before finishing a non-trivial change, do one final verification pass: re-read the request, inspect the full diff, run appropriate tests/checks, and look for missed requirements, wrong assumptions, guideline violations, relevant edge cases, regressions, or unnecessary changes. Fix concrete issues you find and repeat affected checks when needed. Preserve correct code; do not revise merely for the sake of revising.
