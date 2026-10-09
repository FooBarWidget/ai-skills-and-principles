# Draft

## Repository access and pipeline authentication

### Customer repository access

Customers request access to repositories in Forge through AccessDesk by adding an access profile to their team’s existing role. Reader permits reading repositories; Contributor also permits opening pull requests. Both profiles require approval from the team role owner and the repository owner.

When handling customer access requests, share the Harbor guide “Request repository access.” It contains the customer procedure; the internal access handbook points staff to it for this purpose.

### Pipeline authentication

BuildBridge provisions the existing authentication setup for pipelines accessing our cloud account. It creates one identity provider for the Forge organization and one IAM role for each project and service-connection combination. Each role trusts only its designated connection in its designated project.

Pipeline configuration specifies the service connection and role identifier as separate inputs.

The deployment connection permits only pipelines running from main. Pull-request checks therefore use a separate validation connection.

This note documents the existing setup, not a proposed migration. Unlike the retired application/client-secret setup, it requires no application client secret or periodic secret rotation.
