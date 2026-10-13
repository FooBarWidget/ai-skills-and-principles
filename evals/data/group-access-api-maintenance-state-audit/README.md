# Scenario

These are technical reports about the maintenance state of a company-internal API service. The service has been under-maintained for quite some time, and that shows up in the form of errors. The reports are written by a Kubernetes platform engineer, for the purpose of briefing other team members and discussing with the team what to do with the service.

## Additional context (could affect LLM judgements)

The service manages which Entra ID groups can appear in the OIDC tokens used to access Kubernetes clusters. Users belong to too many groups to include them all in a token, so the platform configures Entra ID to include only groups assigned to its login application. The service adds and removes those assignments as groups are onboarded and offboarded, allowing clusters to use the relevant group memberships for authorization.

The service has a small codebase and a straightforward architecture, but its purpose and design depend on specialized knowledge of Entra ID group claims and Kubernetes authentication. Few team members have worked with this part of the platform, and its documentation is poor. The main barrier to understanding is unfamiliar domain context, not implementation complexity.

The team is self-steering and high-agency. This report does not need to be seen by management. No budget approval is needed for investment into fixing the service, but the product owner (part of the team) decides planning and prioritization.

The team also needs to assess whether to completely rearchitect the service, since the broader landscape has changed a lot since the service was introduced.

# Files

## audit1.md

The original report. It is LLM written. Its main problems are:

- Assuming that the reader is very familiar with the service. It talks a lot in terms of internals.
- Using an inflated, executive-briefing tone: sweeping judgments such as "unowned and in poor health" and framing such as "stop the damage" make it read like a pitch for a major remediation initiative. The access-control and reliability risks deserve direct, serious treatment, but this is a small service being discussed by the engineers responsible for it, not a case for management approval. The report should explain the unfamiliar context, state the findings and their consequences plainly, and support discussion of what to fix or redesign without dramatizing the work.

On the other hand, the fact that it starts with a summary, and the generous highlighting of key phrases, helps scanability and skipability a lot. This especially helps readers that *are* familiar with the system and want to get an overview quickly.

## audit2.md

An attempt to improve the document using an LLM, with an old version of the documentation principles. It's overall not an improvement because it has turned into a wall of text and has become less scannable and skipable. The summary section, which provided overview and orientation (at least for people already familiar with the service), has been removed.
