--
name: writing-prompts
description: Guidelines for drafting AI prompts. Use when updating/reviewing AI prompts, including skill contents.
---

## Guidelines for drafting AI prompts

Optimize prompts for token efficiency, not prose brevity: use the fewest tokens that preserve reliable behavior. Remove redundancy and unneeded explanation; prefer shorter equivalents (e.g. "like" over "such as"), compact syntax, and readable fragments. Omit articles or other words when meaning stays clear; grammar and prose polish are secondary. Never save tokens by weakening requirements, distinctions, needed examples, or making critical conditions/actions implicit.

Infer target models from context; otherwise assume GPT-5.6-family or newer. Always assess smaller-model suitability. Briefly state model assumptions and proceed without waiting for confirmation.

Consult current official prompting guidance for the target models and apply relevant recommendations. Do not assume flagship advice applies equally to smaller models. Cite sources outside the prompt, disclose unavailable guidance, and distinguish evidence from inference.

Before responding, silently check the draft against the original requirements and relevant surrounding instructions for omissions, ambiguity, contradictions, unnecessary length, and smaller-model suitability. Keep critical conditions and actions explicit. Fix issues, then recheck for omissions or weakened behavior introduced by revision. Repeat only for concrete remaining issues.

Return the finished prompt with brief notes on material assumptions, tradeoffs, or uncertainties, without a review log. Do not claim performance improvements without testing.
