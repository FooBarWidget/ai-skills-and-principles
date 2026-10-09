## Context

Audience: Platform engineers who understand repositories, pipelines, and cloud IAM, but are new to our team's setup.

Everything below is fictional. These facts are authoritative:

- Forge is our Git hosting service. Harbor is our customer documentation portal.
- Customers request repository access through AccessDesk by adding an access profile to their team's existing role.
- The Reader profile permits reading repositories. The Contributor profile also permits opening pull requests. Both require approval from the team role owner and the repository owner.
- The Harbor guide "Request repository access" contains the customer procedure. Our internal access handbook points staff to that guide so they can share it when handling customer requests.
- BuildBridge provisions pipeline authentication to our cloud account.
- It creates one identity provider for the Forge organization, and one IAM role per project and service-connection combination.
- A pipeline selects the service connection and role identifier separately. Each role trusts only its designated connection in its designated project.
- The deployment connection permits pipelines running from the main branch. Pull-request checks therefore use a separate validation connection.
- This is the existing setup, not a proposed migration. The draft still reflects some terminology from the retired application/client-secret setup.
- The current setup requires no application client secret or periodic rotation.
- BuildBridge's catalog product is BB-472. Its inventory is refreshed nightly. Neither detail changes how staff request access or configure pipelines.
