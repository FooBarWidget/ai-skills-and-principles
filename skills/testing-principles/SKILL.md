---
name: testing-principles
description: Use when coding, writing tests, or reviewing tests. Not applicable to shell scripts, Ansible.
---

## Testing principles (not for shell scripts, Ansible)

- Scale testing to behavioral complexity, regression risk, and failure impact, not diff size. For bug fixes and changes to complex or order-sensitive behavior—such as concurrency/async ordering, state machines, retries/timeouts, protocols, persistence, or security-sensitive code—add the smallest focused regression coverage that meaningfully proves the behavior. If you omit such coverage, state the concrete reason.
- Test observable product behavior and intentional compatibility contracts. Choose the narrowest useful boundary. Avoid tests that only restate implementation steps, derive their expected result from the same production logic being tested, or repeat coverage without distinct regression or diagnostic value. Overlapping tests are useful when they exercise a different integration boundary, branch, platform, failure mode, or contract, improve failure diagnosis, or provide faster or more deterministic feedback.
- Ensure assertions prove the behavior named by the test and each setup step exercises a current path or establishes a relevant precondition. When reviewing existing coverage, treat duplication or apparently unused setup as reasons to investigate purpose and overlap, not as automatic grounds for removal.
- Prefer deterministic tests. For async or concurrent behavior, control scheduling, clocks, I/O, and failure injection where practical rather than relying on sleeps or wall-clock timing. Prefer red/green testing for behavioral changes when practical, especially for bug fixes.
- Before adding, removing, or consolidating coverage, weigh its regression and diagnostic value against runtime, flakiness, setup, and maintenance cost.
- Keep core logic independently testable where practical, and isolate side effects or external interactions when useful. Small, low-risk refactorings to improve testability are fine. If useful coverage would require a broad or intrusive refactor or architectural change, do not expand the current change silently; report the limitation and propose it as follow-up work. Continue the requested work unless the inability to test leaves material uncertainty about correctness, in which case apply the escalation policy.
