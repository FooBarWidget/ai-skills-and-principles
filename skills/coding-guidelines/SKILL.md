---
name: coding-guidelines
description: Use when writing code, or reviewing against guidelines
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
  - Comment non-obvious context the code cannot express clearly: purpose, domain terms, responsibilities, input and output semantics, algorithm stages, invariants, caveats, and decisions. Explain complicated algorithms in high-level manner to aid human readability. Briefly state non-obvious class, module or method responsibilities. Put the comment where that information applies.
  - Write for a capable contributor new to the subsystem or platform. Use natural, plain English and precise technical terms where useful. Define unfamiliar concepts where introduced, explain how they relate to nearby code, and do not make readers derive their meaning from mechanics or call sites.
  - State purpose or constraints before mechanics. Keep comments short and local, put broader or cross-cutting rationale/caveats in the developer handbook, and do not narrate straightforward code.
- Before finishing a non-trivial change, do one final verification pass: re-read the request, inspect the full diff, run appropriate tests/checks, and look for missed requirements, wrong assumptions, guideline violations, relevant edge cases, regressions, or unnecessary changes. Fix concrete issues you find and repeat affected checks when needed. Preserve correct code; do not revise merely for the sake of revising.
