# Repository access and pipeline authentication

## Repository access

Forge is our Git hosting service. Customers request repository access through AccessDesk by adding an access profile to their team's existing role:

- **Reader** permits reading repositories.
- **Contributor** permits reading repositories and opening pull requests.

Both profiles require approval from the team role owner and the repository owner.

When handling customer requests, share the guide "Request repository access" in Harbor, our customer documentation portal. The internal access handbook links to that guide.

## Pipeline authentication

BuildBridge provisions pipeline authentication to our cloud account. It creates one identity provider for the Forge organization and one IAM role for each project and service-connection combination.

A pipeline selects its service connection and role identifier separately. Each role trusts only its designated service connection in its designated project, so both selections must match the role's trust configuration.

The deployment connection permits pipelines running from the main branch. Pull-request checks therefore use a separate validation connection.

This is the current setup. It requires no application client secret or periodic rotation; guidance for the retired application/client-secret setup no longer applies.
