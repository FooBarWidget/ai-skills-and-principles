# Skill design notes

We include prose recommendations common in many technical writing guidelines, such as "use active voice". We also address common AI prose issues:

- They often turn everything into a mini-TED-talk:
  - Sections such as "Why it works/matters". I've yet to see such a section that's useful. Most of the time they're just unnecessary repeats of what's already said. We want to only allow them if they add value, and there are no better headings.
  - Inflated language: "the real test", "an actual budget conversation", "what most get wrong". These phrases introduce unsupported contrasts or add emphasis without information.
- Repeating details unnecessarily. Even for short documents, AI often writes verbosely, where half of the writing is just a rehash of what's already said.

Good documentation should be focused on the main point. Long documents are not necessarily bad, unnecessary information is. Therefore, we explicitly prefer "concise" over "brief/short". With the latter, the AI may reduce length at the cost of omitting important information.

On a higher level than prose, audience, purpose, information flow and document structure matter a lot:

- Diataxis is helpful for its philosophy about categories of reader needs. But the AI may interpret Diataxis as rigid rules, so we explicitly explain that Diataxis should be considered guidelines, and which core principles from Diataxis are the most important for our purposes.
- Diataxis alone does not provide enough guidance about information flow and document structure, so we separately address that. Things such as what consistitutes proper use of headings, or when to split or merge documents, or what makes a good conclusion.

Regarding "Infer intent and rationale when reasonably supported by context": when asking the AI to review or fill in gaps in existing documents and comments, the AI may not have enough context to do a proper job. In those situations, we want the AI to have a reasonable discussion with the user rather than guessing or refusing to work.

Regarding descriptions of behavior: the AI may describe behavior exhaustively. This comes at the risk of obscuring the main point, drowning the user in edge case details. Depending on the situation, not all details are worth documenting explicitly.

Regarding explanations of technical concepts: whether it deserves explanation depends on the reader's likely background. For example, a typical Ruby does not need explanations about Ruby language constructs, but may appreciate explanations about uncommon operating system-specific caveats.
