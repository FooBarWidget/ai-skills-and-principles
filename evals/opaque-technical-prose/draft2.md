# Draft

## Repository access and pipeline authentication

Customers request Reader or Contributor access through AccessDesk, subject to the required approvals. The customer guide is linked from the internal access handbook.

BuildBridge manages pipeline authentication through an organization-level identity provider, project-specific IAM roles, and scoped trust policies. Pipelines configure their authentication inputs separately, with distinct connections for deployment and PR validation.

The documentation reflects the current setup. Obsolete application-secret rotation guidance no longer applies.
