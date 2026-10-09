# Draft

## Repository access and pipeline authentication

AccessDesk role-profile augmentation supplies Reader and Contributor access subject to role-owner/repository-owner authorization. The customer procedure is linked from the internal access handbook. Reader is for reading and Contributor is for contribution, with the relevant approvals being required.

The BuildBridge configuration encompasses organization-level identity-provider provisioning, project/connection role materialization, separately parameterized connection and role selection, and project/connection-scoped trust. Deployment and validation connections are separate due to branch eligibility. The catalog product is BB-472 and inventory refresh is nightly.

Application-secret rotation guidance is no longer applicable to this setup. The setup is the current setup and this note documents the current arrangements.
