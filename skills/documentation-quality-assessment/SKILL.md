---
name: documentation-quality-assessment
description: Assesses documentation quality. Use when asked to review documentation, and after writing or substantially revising documentation to self-review before delivery.
---

# Documentation quality assessment guide

This guide covers assessment of individual documents, related collections, and alternative revisions, against the qualitative metrics below. After writing or substantially revising documentation, self-review before delivery, within the requested scope.

Before assessing, establish the audience, purpose, and relevant working context from the request and available context. Follow “Missing evaluation context” for material gaps; do not ask the user to repeat established context.

## Preparing an assessment

- Respect the requested assessment scope. When self-reviewing revisions, use comparison mode if a relevant baseline is available; otherwise use standalone mode and disclose any resulting limit on assessing preservation. Do not fabricate an earlier version or approximate one from memory.
- When revision comparison is anticipated, preserve the relevant baseline before overwriting it if it cannot otherwise be recovered exactly.
- When delegating (using subagents):
  - Provide the reviewer with:
    - This skill's accessible location and an instruction to read it before assessing.
    - The assessment task and scope, audience, purpose, relevant working context, and revision constraints.
    - Accessible, exact versions of the assessed documents, clearly distinguishing revisions, collection members, and supporting sources. For comparison, include both the baseline and candidate.
    - Material unresolved questions and relevant source locations.
  - Token-efficient operation: prefer a compact task brief and file paths or revision references over copied documents or the full conversation. Verify that the reviewer can access the referenced material. Do not substitute summaries or diffs for inspecting the documents; use the existing coverage and sampling rules for large collections.

## How to assess

- Establish relevant reader scenarios from the audience, purpose, and working context. Include concrete reading tasks, such as getting an overview, locating one issue, or understanding an explanation. Identify which tasks are essential to the stated purpose and which are secondary. Treat familiarity and reading mode separately: unfamiliar readers may skim; familiar readers may read closely. Assess only scenarios that materially affect the experience.
- Judge against the stated purpose. Do not impose requirements for a more ambitious document, such as treating a discussion note as a complete implementation plan.
- Ground judgments in specific passages, omissions, or structural features and their consequences for readers.
- Assess visual presentation from the rendered document when available. If only source text is available, assess the structure it reveals and qualify conclusions that depend on layout.
- Score each metric per scenario where experience differs. Combine scenarios only when both rating and rationale are materially the same. Do not average away a serious problem for one intended audience or let strength in one metric compensate for a material failure in another.
- Base the overall assessment on how well the supplied documentation supports essential reader tasks. Explain which shortcomings determine suitability or comparative preference, and why; do not infer overall improvement from isolated improvements. Assess revisions as supplied, separately from which would be easiest to improve.
- Use "not applicable" when a metric genuinely does not apply, and "insufficient evidence" when it cannot be assessed. Distinguish source fidelity from independently verified correctness; do not claim the latter without adequate evidence.
- For assessment-only requests, do not rewrite the documentation unless requested. During self-review of authorized writing or editing, use the findings to revise within the requested scope.

### Assessment scope

Distinguish the documentation being assessed from supporting sources, and related documents within one collection from alternative revisions. If their roles are unclear and affect the assessment, clarify them.

For a collection, assess relevant individual documents and how they work together. Apply the existing metrics to these collection-level concerns:

- **Reader journeys:** Assess representative tasks through relevant entry routes: browsing navigation, searching, following links, and arriving directly on an interior page. Establish whether readers can discover and follow a usable route; finding an answer after inspecting the entire collection does not establish that readers can find it.
- **Independent entry:** Check whether readers arriving directly can identify a page's subject, applicability, and prerequisites, understand its essential context, and reach relevant background or next steps. Do not assume they read preceding pages. Sequential material should make its sequence and dependencies clear.
- **Shared explanations:** Check whether substantive shared explanations have a clear primary home, which may be a page or section. Distinguish unnecessary duplication and competing explanations from useful local definitions, reminders, summaries, and warnings. Do not require every page to repeat all background, or reward centralization that forces excessive link-following to understand or complete a task.
- **Document boundaries:** Assess whether each page has a coherent purpose, whether its contents belong together for relevant reader tasks, and whether separate pages offer useful independence. Split at distinct purposes or major topics—subjects readers seek independently—only when separate documents materially improve understanding or navigation, or readers naturally expect them. Each resulting document should have enough substance and a clear standalone purpose; regroup small remnants with related material.
- **Merging:** Merge short documents when they serve closely related reader needs and separation adds navigation overhead without useful independence. Preserve meaningful distinctions through sections. Judge split/merge recommendations by their effects on reader tasks, including the reading and navigation burden they introduce, not by document length alone.
- **Titles and labels:** Assess titles, navigation labels, and link text in the contexts where readers choose destinations. Can readers predict each destination's purpose and distinguish neighbouring choices without opening several pages experimentally? Check for vague, misleading, overlapping, or unnecessarily narrow scopes.
- **Navigation:** Assess categorization, breadth, depth, default expansion, and cross-links together. Check whether readers can locate relevant material without excessive scanning, exploratory expansion, or backtracking. Follow stated navigation constraints, but do not treat compliance alone as proof of usability.
- **Consistency:** Check whether terminology, prerequisites, explanations, and instructions agree across documents or clearly distinguish differences in audience, scope, version, or applicability.

Respect documents' different audiences and purposes. Report consequential local failures separately; do not let good pages conceal a broken reader journey.

State what was inspected and whether coverage was complete or sampled. For large collections, select representative task paths and explain the selection. Limit conclusions to inspected evidence; do not generalize sampled success to the entire collection.

### Missing evaluation context

Before scoring, check whether the audience, purpose, and working context are sufficiently established. Unless the supplied context indicates otherwise, assume varied subject-matter familiarity within the intended audience, including readers less familiar with this specific subject. Do not assume they lack the general knowledge expected of that audience. State material assumptions. Do not infer domain familiarity solely from job titles or decision authority solely from document format.

If missing context could materially change a rating, comparative preference, or improvement recommendation:

- Identify the affected judgment and missing information. If interaction is available, ask focused questions before finalizing affected judgments. Group related questions and continue with findings that do not depend on the answers.
- If clarification is unavailable or inconclusive, mark affected judgments "insufficient evidence". Where useful, explain how they differ under plausible scenarios without selecting an unsupported scenario.
- Distinguish uncertainty about the readers from context the document demonstrably needs to supply. Do not penalize the document for the former.
- Keep unresolved judgments visible in the overall assessment. Do not treat them as passes; make the conclusion conditional or withhold it if they could change it.

## Modes

### Standalone mode

Applicable when one document or related collection is designated for assessment, with or without supporting sources. Assess how well it serves its intended readers and purposes without requiring an earlier revision. Use the metric scales below. Identify material weaknesses even when the overall rating is favorable.

### Comparison mode

Applicable when two or more alternative revisions of the same document or collection are designated for comparison. Each revision may contain multiple related documents. Supporting sources and documents within one collection do not themselves trigger comparison mode.

- Inspect each revision directly, using comparable coverage and reader tasks when sampling collections. Do not infer improvement from previous evaluation results, revision labels, filenames, authorship, or an assumption that newer revisions are better.
- Apply the same scenarios and expectations to all revisions. Give each an absolute rating using the scales below, then compare them directly for each metric and scenario.
- For each metric and scenario, identify the preferred revision(s), "no meaningful difference", or "unresolved tradeoff". For more than two revisions, make clear which revisions each judgment covers. Use "insufficient evidence" when the comparison cannot be established. "No meaningful difference" means practical equivalence, not merely identical scores.
- Explain the specific gain or regression and its practical significance. Explicitly report meaningful differences within the same rating band. Use “unresolved tradeoff” when relevant gains and losses cannot be resolved from the stated purpose and priorities; identify what would resolve it.
- Assess preservation of material facts, qualifications, intent, and recommendations against available sources and revision constraints. The earlier revision is evidence of previous content, not automatically ground truth. Distinguish supported corrections and permitted changes from unsupported additions or losses.
- Conclude which revision(s) best serve the stated purpose, whether they are practically equivalent, or why the choice remains unresolved. For more than two revisions, identify which revisions each conclusion covers. Do not decide by counting metric wins or summing ordinal ratings. Identify material regressions separately, especially in fidelity or essential reader tasks. A better revision can still be inadequate.

## Output format

For self-review during a writing or editing task, apply the criteria without producing a separate assessment report unless requested. Deliver the requested artifact and flag material unresolved issues.

Clarification questions may precede the assessment. Structure the assessment with headed sections as below. Keep the assessment proportionate to the material and consequential findings. Group scores only as allowed above. When one issue affects several metrics, explain the issue once and state its distinct consequence under each affected metric without repeating the full explanation.

1. **Overall assessment.** Explain whether the documentation suits the intended audience, purposes, and working context, drawing on the metric findings. Identify the most consequential strengths, weaknesses, and unresolved context gaps. In comparison mode, state the preferred revision(s), practical equivalence, or unresolved tradeoff, including material regressions. Make conclusions conditional when missing context could change them and limit their scope when coverage is incomplete.
2. **Highest-value improvements**, when helpful. Prioritize changes that improve reader outcomes; preserve existing strengths. Do not recommend extra content or restructuring without explaining the problem it solves.
3. **Per-metric, per-scenario scores.** Identify scenarios and assessed scope within this section. For collections, state inspection coverage and distinguish collection-wide from document-specific findings. Attach concise rationale and evidence. In comparison mode, include each revision's ratings and the direct comparative judgment.
4. **Other notes**, only when useful, including material evidence limits or assumptions.

## Qualitative metrics (informed by ISO 24495-1)

### Reader effort

How much *avoidable* effort does the document impose on readers to follow, understand, or use its content, given its purpose? Necessary attention, reflection, and technical reasoning are not defects. Prefer concise expression when it preserves meaning, necessary context, and ease of understanding. Assess avoidable wording, repetition, and detail, and whether readers must process information before they need it. Consider both total reading burden and how much readers must absorb at once; visual spacing alone does not resolve excessive information load. Do not reward compression that makes relationships implicit or forces reconstruction.

- Low: Readers can follow, understand, or use the content without substantial avoidable searching, backtracking, reconstruction, or irrelevant reading.
- Medium: The document remains understandable and usable, but noticeable friction makes readers work unnecessarily: scattered explanations, unclear transitions, distracting detail, or gaps they can reasonably resolve.
- High: Writing or organization substantially obstructs understanding or use. Readers must repeatedly reconstruct meaning, supply important missing context, traverse irrelevant material, or risk misinterpretation.

### Reading-mode support

Does the document support how its intended readers need to read it—quick overview, selective consultation, sustained understanding, or a combination—without obscuring essential meaning?

Where overview or selective reading matters, assess visual scannability:

- Visibility: Can readers identify key points, distinctions, and actions without reading every sentence?
- Grouping: Are meaningful units visibly separated, with boundaries that help readers recognize their roles?
- Selection: Can readers locate relevant material and confidently skip other material without missing essential context?

Judge these effects, not the presence or quantity of headings, bullets, whitespace, or short paragraphs. For overview and selective-reading scenarios, assess what readers can discover and understand without close reading throughout; do not credit them with understanding obtained only through the evaluator's full inspection. Dense prose can obstruct scanning; excessive fragmentation can obstruct sustained understanding.

- Good: Supports the intended reading modes without losing essential meaning. Where scanning matters, readers can recognize key points and select relevant detail without close reading throughout.
- Partial: Useful reading paths exist, but buried key points, weak grouping, unclear navigation, hidden dependencies, or disrupted progression create noticeable friction.
- Poor: Readers cannot reliably use an essential reading mode. They must read extensively to discover key points or locate relevant material, or fragmentation and hidden dependencies substantially obstruct understanding.

### Orientation support

Can readers establish the subject, relevance, main message, and scope early enough to guide their reading, and recognize how to proceed?

Assess this in the intended reading mode. Where overview matters, the opening should convey the main message and essential context concisely, with supporting explanations and detail available later. Readers should be able to stop after the overview with an accurate understanding of the main message, or select where to read further. Retain qualifications needed to prevent a misleading first impression. Do not require a dedicated summary when the opening already provides effective orientation.

- Good: Readers acquire the understanding needed to interpret the document and choose how to proceed, without substantial inference or premature detail.
- Partial: Readers can identify the subject and relevance, but an important part of the main message, scope, or reading path remains unclear or requires avoidable work.
- Poor: Readers must read extensively or reconstruct the document’s main message, relevance, or scope before they can approach it effectively.

### Synthesis quality

Does the document explain the relationships and significance needed for its purpose, rather than merely collect information?

- Good: Connects relevant information and explains its significance sufficiently for the document’s purpose, without unsupported conclusions.
- Partial: Explains some relationships, but readers must still assemble an important explanation, distinction, or argument.
- Poor: Mainly juxtaposes information or gives superficial conclusions; essential relationships remain unexplained or are misrepresented.

### Tone and stance fit

Do the language, emphasis, and author's stance suit the audience, purpose, and working context?

Assess whether formality, urgency, rhetorical emphasis, and implied authority are proportionate. Check whether the document appropriately presents findings, recommendations, decisions, and open questions, respecting the roles of author and readers.

Assess cumulative framing as well as individual phrases. For example, what importance, urgency, scale of response, authority, and decision status does the document lead readers to infer? Consider titles, summaries, severity labels, recommendations, and procedural requirements together. Ground mismatches in their likely effects on the intended discussion or action.

Do not reward professional-sounding language by itself or penalize directness, strong recommendations, formal structure, or justified urgency. Identify concrete mismatches and their effects; distinguish audience fit from personal stylistic preference.

- Good: Tone and stance suit the situation. Emphasis is proportionate, and recommendations and open decisions are presented appropriately.
- Partial: Noticeable mismatches—such as inflated importance, unnecessary ceremony, excessive casualness, or premature decisiveness—create friction, but the document remains suitable for its main purpose.
- Poor: Tone or stance materially undermines the purpose, misrepresents the working relationship or decision status, or substantially distorts readers' perception of importance or urgency.

### Context sufficiency

Are needed concepts, prerequisites, and rationale available without unnecessary elementary explanation?

- Good: Supplies relevant prerequisites and detail at suitable depth; additional background is accessible without burdening readers who do not need it.
- Partial: Contains noticeable gaps or excess, but readers can still understand the central content.
- Poor: Missing prerequisites or overwhelming irrelevant explanation substantially obstruct understanding.

### Fidelity

Are claims, qualifications, intent, and recommendations supported and preserved appropriately?

- Good: Preserves material facts, qualifications, and intended meaning; distinguishes evidence, inference, and proposals where necessary.
- Partial: Has minor inaccuracies, omissions, or shifts in emphasis that do not materially change interpretation.
- Poor: Introduces or loses material information, certainty, or intent in ways that change interpretation or could mislead.
