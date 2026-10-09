- Date: 2026-10-05
- Commit: 314f77485c3ff181f7dbd2d45b8a45f4bda4b836
- Assessor: VSCode Github Copilot, Claude Opus 5.5 (high)

## Assessment 1: meaning

### draft1

**Result: 1 of 7 pass.** The draft names most of the right things, but its abstract wording ("augmentation", "materialization", "branch eligibility") hides the facts a reader needs.

**1. How do customers request access, and who approves it? Fail**
> "AccessDesk role-profile augmentation supplies Reader and Contributor access subject to role-owner/repository-owner authorization."

The approvers are close enough: "role-owner/repository-owner". The method is too vague. "Role-profile augmentation" doesn't say that customers add a profile to their team's existing role. It also doesn't say that customers are the ones who request access.

**2. Which profile does a customer need to open PRs? Fail**
> "Reader is for reading and Contributor is for contribution"

Reader is described correctly. "Contribution" never mentions opening pull requests, so the draft doesn't show that Contributor is the profile needed for PRs.

**3. Why does the internal handbook point to the Harbor guide? Fail**
> "The customer procedure is linked from the internal access handbook."

The draft never mentions Harbor. It also never gives a reason for the link, such as letting staff share the procedure when handling requests.

**4. How are the provider, roles, and connections related? Fail**
> "organization-level identity-provider provisioning, project/connection role materialization, … and project/connection-scoped trust"

- "Organization-level" roughly suggests one provider per organization.
- "Project/connection role materialization" doesn't say there is one role per project/connection pair.
- "Project/connection-scoped trust" doesn't clearly say that each role trusts only its own pair.

**5. What does a pipeline select? Pass**
> "separately parameterized connection and role selection"

This says the connection and role are selected separately. It's weak in two ways: it doesn't name the pipeline as the thing doing the selecting, and it says "role" rather than "role identifier".

**6. Why is validation separate from deployment? Fail**
> "Deployment and validation connections are separate due to branch eligibility."

The draft doesn't say that the deployment connection only works from `main`. It also doesn't say that this is why PR checks need a separate connection.

**7. Is this a migration, and must staff rotate a client secret? Fail**
> "Application-secret rotation guidance is no longer applicable to this setup. The setup is the current setup and this note documents the current arrangements."

- The draft does convey that this is the existing setup, not a migration.
- It implies that rotation isn't needed.
- It doesn't say that no client secret is required. "Rotation guidance is no longer applicable" could still be read as saying a secret exists but no longer needs rotating.

### draft2

1. **Fail** — “Customers request Reader or Contributor access through AccessDesk, subject to the required approvals.” The draft doesn’t say customers add a profile to their team’s existing role, or name the team role owner and repository owner as approvers.

2. **Fail** — “Customers request Reader or Contributor access…” The draft doesn’t state which profile permits opening PRs or that Reader only permits reading.

3. **Fail** — “The customer guide is linked from the internal access handbook.” This says a link exists, but not that staff share the customer procedure when handling access requests.

4. **Fail** — “an organization-level identity provider, project-specific IAM roles, and scoped trust policies.” The draft doesn’t establish one provider per organization, one role per project-and-connection pair, or trust restricted to that pair.

5. **Fail** — “Pipelines configure their authentication inputs separately.” “Authentication inputs” doesn’t specify that pipelines select the connection and role identifier separately.

6. **Fail** — “with distinct connections for deployment and PR validation.” The draft doesn’t explain that the deployment connection is restricted to `main`, requiring a separate connection for PR checks.

7. **Fail** — “The documentation reflects the current setup. Obsolete application-secret rotation guidance no longer applies.” This indicates the setup is current and rotation guidance is obsolete, but doesn’t state that no application client secret is required.

### draft3

1. **Pass** — “Customers request access to repositories in Forge through AccessDesk by adding an access profile to their team’s existing role.” “Both profiles require approval from the team role owner and the repository owner.”

2. **Pass** — “Reader permits reading repositories; Contributor also permits opening pull requests.”

3. **Pass** — “When handling customer access requests, share the Harbor guide ‘Request repository access.’ It contains the customer procedure; the internal access handbook points staff to it for this purpose.”

4. **Pass** — “It creates one identity provider for the Forge organization and one IAM role for each project and service-connection combination. Each role trusts only its designated connection in its designated project.”

5. **Pass** — “Pipeline configuration specifies the service connection and role identifier as separate inputs.”

6. **Pass** — “The deployment connection permits only pipelines running from main. Pull-request checks therefore use a separate validation connection.”

7. **Pass** — “This note documents the existing setup, not a proposed migration. Unlike the retired application/client-secret setup, it requires no application client secret or periodic secret rotation.”

## Assessment 2: readability

## draft1

- **Orientation: 0 (fails)**
  - The only framing is the heading, "Repository access and pipeline authentication." It names the topic, but it doesn't say who the guidance is for or what the setup does.
  - The first sentence goes straight to technical ingredients: "AccessDesk role-profile augmentation supplies Reader and Contributor access subject to role-owner/repository-owner authorization."
  - The pipeline paragraph does the same, opening with "The BuildBridge configuration encompasses organization-level identity-provider provisioning…" It never says what BuildBridge is for.
  - The only sentence that resembles orientation comes last: "this note documents the current arrangements." It still doesn't name a reader or a purpose.

- **Explanatory prose: 0 (fails)**
  - Labels stand in for explanations: "role-profile augmentation," "project/connection role materialization," "separately parameterized connection and role selection," and "project/connection-scoped trust."
  - "Deployment and validation connections are separate due to branch eligibility" gives a cause as a label. It doesn't say which branches are eligible for which connection.
  - "subject to role-owner/repository-owner authorization" doesn't say whether both owners must approve or either one.
  - Where it does try plain sentences, they are circular: "Reader is for reading and Contributor is for contribution."
  - "The customer procedure is linked from the internal access handbook" is readable, but it doesn't name the procedure or say what staff should do with it.

- **Economy: 0 (fails)**
  - **Repetition:** "with the relevant approvals being required" repeats "subject to role-owner/repository-owner authorization." "The setup is the current setup and this note documents the current arrangements" says "current" twice and adds nothing.
  - **Irrelevant detail:** "The catalog product is BB-472 and inventory refresh is nightly" doesn't connect to any action or decision in the draft.
  - **Lost meaning:** The draft is short, but it gets there by compressing ideas into labels, not by cutting waste. As a result, needed meanings are missing:
    - what Contributor permits beyond "contribution"
    - what "branch eligibility" restricts
    - what replaces "application-secret rotation"

Brevity does not earn credit here, because important constraints are hidden rather than kept.

## draft2

## Assessment of draft2.md

- **Orientation: 1 (partly succeeds)**
  - **What works:** The draft gives a rough purpose before it names the components. Examples: "Customers request Reader or Contributor access through AccessDesk" and "BuildBridge manages pipeline authentication through…"
  - **Audience:** The draft never says who the guidance is for. Nothing tells the reader it is written for platform engineers who are new to the team's setup.
  - **Setup:** The purpose and the parts arrive in the same sentence: "through an organization-level identity provider, project-specific IAM roles, and scoped trust policies." The draft doesn't say what pipelines authenticate to (the cloud account). It doesn't say what Reader and Contributor allow.
  - **Status:** The statement that this is the current setup comes last: "The documentation reflects the current setup." A reader needs that up front.

- **Explanatory prose: 0 (fails)**
  - **Labels instead of explanations:** Most relationships are replaced by short labels:
    - "subject to the required approvals" doesn't say whose approval is needed.
    - "scoped trust policies" doesn't say what each role trusts.
    - "Pipelines configure their authentication inputs separately" doesn't say which inputs are set or why they are separate.
    - "distinct connections for deployment and PR validation" doesn't say why validation needs its own connection.
  - **Security rules hidden:** These labels hide the security restrictions. The draft never says that a role trusts only one connection in one project. It never says that the deployment connection works only for main-branch pipelines.
  - **Handbook sentence:** "The customer guide is linked from the internal access handbook" is a real sentence. But it doesn't name the guide or say that staff share it with customers.
  - The smooth prose doesn't make up for these gaps.

- **Economy: 0 (fails)**
  - **What works:** There is no repetition. Irrelevant details are left out, such as the catalog product number and the nightly inventory refresh.
  - **What fails:** The draft gets short mainly by dropping meanings the reader needs. The criterion rules this out. Missing items:
    - who approves access (the team role owner and the repository owner)
    - that access works by adding a profile to the team's existing role
    - what Reader and Contributor each permit
    - the name of the Harbor guide
    - that there is one role per project and service-connection combination
    - that a pipeline selects the connection and the role identifier separately
    - that the deployment connection is limited to the main branch
    - that the setup needs no client secret
  - **Vague sentence:** "Obsolete application-secret rotation guidance no longer applies" suggests the secret point without saying it. A reader can't tell whether some other secret still needs rotating.

I used context.md only to identify which required points are missing. I didn't treat the draft as saying anything it doesn't actually state.

## draft3

- **Orientation: 1 (partly succeeds)**
  - **What works:** Each section opens by saying what the setup does before it goes into detail. The access section starts with *"Customers request access to repositories in Forge through AccessDesk by adding an access profile to their team's existing role."* The pipeline section starts with *"BuildBridge provisions the existing authentication setup for pipelines accessing our cloud account."*
  - **Gap 1: the audience is never named.** The reader can only infer that it's staff from *"When handling customer access requests, share the Harbor guide…"*. There is no introduction under the H2 heading.
  - **Gap 2: the document's purpose comes last.** *"This note documents the existing setup, not a proposed migration"* is the final paragraph. It should come first.
  - **Gap 3: names appear with no explanation.** BuildBridge, AccessDesk and Harbor are never introduced. Only Forge's role can be partly guessed, from "repositories in Forge".
  - **Gap 4: the pipeline section rushes into components.** Its opening sentence is vague ("the existing authentication setup"). The next sentence already lists the identity provider and IAM roles, without saying what problem they solve.

- **Explanatory prose: 2 (succeeds)**
  - Relationships are written as sentences, not replaced by labels. Examples:
    - *"Reader permits reading repositories; Contributor also permits opening pull requests."*
    - *"Each role trusts only its designated connection in its designated project."*
    - *"The deployment connection permits only pipelines running from main. Pull-request checks therefore use a separate validation connection."*
  - The causal "therefore" explains why the validation connection exists, instead of just naming it.
  - **Minor weakness 1:** *"Pipeline configuration specifies the service connection and role identifier as separate inputs"* sits next to the trust sentence but isn't linked to it. The draft doesn't say the two inputs must match.
  - **Minor weakness 2:** The identity provider is mentioned (*"one identity provider for the Forge organization"*) but its relationship to the roles isn't explained.
  - Neither weakness is a label standing in for an explanation, so the score stays at 2.

- **Economy: 2 (succeeds)**
  - The draft is short and repeats itself very little. Irrelevant operational details are absent.
  - Required meanings are kept:
    - **Both approvals:** *"Both profiles require approval from the team role owner and the repository owner."*
    - **The main-only restriction:** *"permits only pipelines running from main"*
    - **The per-connection trust limit:** *"trusts only its designated connection in its designated project"*
    - **The absence of secrets:** *"requires no application client secret or periodic secret rotation"*
  - **Small leftover redundancy 1:** *"the internal access handbook points staff to it for this purpose"* adds little, since the reader has just been told to share the guide.
  - **Small leftover redundancy 2:** "existing" appears twice (*"existing authentication setup"*, *"documents the existing setup"*).
  - **Small leftover redundancy 3:** "secret" appears three times in the last sentence.
