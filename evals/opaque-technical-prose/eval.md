A rewrite leaves dense jargon, vague references, and unexplained technical relationships in place instead of using the supplied context to make them understandable. The eval checks whether an internal reference becomes clearer while preserving required meaning and removing irrelevant detail.

## Procedure

Feed `prompt.md`, `context.md` and `draft1.md` to an AI with our skills enabled.

## Assessment 1: meaning

> When assessing with AI, consider the text below as prompt, and attach `context.md` and the candidate document.

Assess the given draft. For each answer below, quote supporting text from the draft. Do not fill gaps using any context outside the draft. Use the expected answers to grade, but the evidence must come from the draft. Output as a list, not table.

For each question, choose a result:

- Pass: The document communicates the required meaning, supported by quoted text. Equivalent wording is fine.
- Fail: The meaning is missing, contradicted, or too vague to establish. Quote the vague or contradictory text where available; otherwise state "not stated."

Questions and answers:

1. How do customers request access, and who approves it?
   Required meaning: Add a profile to the existing team role through AccessDesk; team role owner and repository owner approve.
2. Which profile does a customer need to open PRs?
   Required meaning: Contributor; Reader only permits reading.
3. Why does the internal handbook point to the Harbor guide?
   Required meaning: So staff can share the customer procedure when handling access requests.
4. How are the provider, roles, and connections related?
   Required meaning: One provider per organization; one role per project/connection pair; trust restricted to that pair.
5. What does a pipeline select?
   Required meaning: The connection and role identifier separately.
6. Why is validation separate from deployment?
   Required meaning: The deployment connection is restricted to `main`, so PR checks need another connection.
7. Is this a migration, and must staff rotate a client secret?
   Required meaning: Existing setup; no client secret or rotation required.

## Assessment 2: readability

> When assessing with AI, consider the text below as prompt, and attach `context.md` and the candidate document.

Assess the given draft based on the following criteria. You can. Use `0 = fails`, `1 = partly succeeds`, `2 = succeeds`. Quote supporting text from the draft. Do not fill gaps using any context outside the draft. Don't collapse everything into one average: fluent prose should not compensate for a missing security restriction. Output as a list, not table.

- Orientation: Does the document establish who the guidance is for and what the setup does before introducing its technical ingredients?
- Explanatory prose: Does it explain relationships in sentences, rather than substitute labels such as “branch eligibility” or “role materialization”?
- Economy: Does it remove repetition and irrelevant detail without sacrificing the required meanings?

## Eval calibration

Must fail assessment:

- `draft1.md`: mostly factual, but poor readability.
- `draft2.md`: a polished, aggressively shortened summary. Readable on the surface, but missing relationships.

Must pass assessment:

- `draft3.md`: a clear rewrite. Preserves the required meanings and removes clutter.
