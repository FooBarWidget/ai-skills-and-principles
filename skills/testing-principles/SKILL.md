---
name: testing-principles
description: Use when coding, writing tests, or reviewing tests. Not applicable to shell scripts, Ansible.
---

## Testing principles (not for shell scripts, Ansible)

- Scale testing to behavioral complexity, regression risk, and failure impact, not diff size. For bug fixes and changes to complex or order-sensitive behavior—such as concurrency/async ordering, state machines, retries/timeouts, protocols, persistence, or security-sensitive code—add the smallest focused regression coverage that meaningfully proves the behavior. If you omit such coverage, state the concrete reason.
- Prefer deterministic tests. For async or concurrent behavior, control scheduling, clocks, I/O, and failure injection where practical rather than relying on sleeps or wall-clock timing. Avoid tests that merely mirror the implementation or duplicate existing coverage. Prefer red/green testing for behavioral changes when practical, especially for bug fixes.
- Keep core logic independently testable where practical, and isolate side effects or external interactions when useful. Small, low-risk refactorings to improve testability are fine. If useful coverage would require a broad or intrusive refactor or architectural change, do not expand the current change silently; report the limitation and propose it as follow-up work. Continue the requested work unless the inability to test leaves material uncertainty about correctness, in which case apply the escalation policy.
