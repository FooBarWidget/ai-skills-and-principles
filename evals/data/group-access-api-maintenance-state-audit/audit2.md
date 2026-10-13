# Group Access API audit

**Date:** 2026-08-18  
**Scope:** this repository at `7c4e2a1`, the deployed stacks in `delivery-prod`
(`111111111111`) and `delivery-test` (`222222222222`), the Entra objects the API
changes, and the legacy clients in `cloud-services/fleet-infrastructure`. The method was source review, `npm audit`, and read-only queries of AWS, Microsoft Graph, and Azure DevOps. No infrastructure or access state was changed.

## Assessment

This API controls which Entra group memberships can appear in users' login tokens for the self-managed Kubernetes fleet on EC2. All clusters use the same Entra enterprise application for group-based access. Removing a group's assignment can therefore affect access across the fleet, not just the cluster that requested the change.

The API cannot reliably preserve clients' group references or remove assignments when those references end. In the 24-hour audit window, about 56 percent of requests returned HTTP 500. Failed DELETE requests are not retried by the legacy clients, so their references can remain indefinitely. A separate handler bug can leave a group assigned even when its final reference has been removed. These are different failures and require different repairs (R1, B1, B3).

The authorization boundary is also insufficient. Admitted callers can change other clusters' references and can unassign groups the API does not track (S1). Separately, a shared Entra credential allows changes outside the API and is exposed through policies covering three organizational unit paths and two additional accounts (S2). Fixing API authorization alone will not close that second route.

The immediate recommendation is to assign a remediation owner, contain unauthorized deletion, and coordinate restriction of the shared credential with `fleet-infrastructure`. Request handling should be stabilized alongside that work. Security containment should not be deferred solely because the performance fix is smaller. Changes need focused tests and a production approval step: the current non-production deployment receives no client traffic and targets the production Entra application.

## How references control fleet access

Clients call `PUT` or `DELETE /v1/{groupId}/{key}` through API Gateway using AWS IAM authentication. A key identifies a client's need for a group, such as a cluster namespace or a Terraform namespace-admin resource. DynamoDB stores one item per group, with the keys that reference it.

For a group managed by this API, the intended behavior is straightforward: the group should be assigned to the Entra application while at least one reference remains. Removing one key should not affect other references. Removing the final reference should remove the assignment. Groups managed outside the API need separate protection; an absent table item is not permission to delete their assignments.

The handler uses the Aster-K8S client secret from Secrets Manager to call Microsoft Graph and change assignments on `fleet-k8s-login`. That application has `groupMembershipClaims: ApplicationGroup`, which limits group claims to memberships in groups assigned to the application. The Kubernetes API servers validate OIDC tokens and map those claims to `entra:<groupId>` for role-based access control (RBAC). An assignment makes a group's membership eligible for inclusion in tokens; it does not give every user that membership or grant permissions independently of RBAC.

The design document says this filtering is intended to avoid the 200-group claim limit. Unneeded assignments increase eligible memberships for users who belong to those groups. Total assignments alone do not show whether any user exceeds the limit; the supplied report does not give affected users' claim sizes.

The legacy access-controller uses keys `<cluster>-ns-<namespace>` and `<cluster>-rb-<rolebinding>`. A Terraform provider uses `<cluster>-tf-namespace-admins`. Both clients live in `fleet-infrastructure`. The RoleBinding key omits the namespace, so distinct bindings can accidentally share a single reference (B4).

## Why the current state is unsafe

### Failed requests lose deletions

Lambda is limited to one execution at a time. Each request fetches the secret, obtains an Entra token, and lists the application's assignments through Graph, even when the request would leave the reference state unchanged. At the audit snapshot, listing all 472 assignments required about ten pages. Median request latency was 809 ms.

Clients repeatedly send the same state: 128,400 requests covered 1,479 distinct keys in the 24-hour window, averaging about 87 requests per key. This work occupies the single execution slot and is consistent with the observed throttling: Lambda recorded 1.93 million throttles over 30 days (R1).

The consequence is not just a slow API. A subsequent periodic PUT may eventually register an unchanged reference, but the legacy clients do not retry failed DELETEs. A missed DELETE leaves an obsolete reference in DynamoDB, which can keep a group assigned. The supplied evidence does not quantify how many obsolete references came from this mechanism rather than other defects or abandoned clusters.

### DynamoDB and Entra disagree

A separate deletion path reads only the first page of assignments: 50 out of 472. If the target assignment is on a later page, the handler leaves it in Entra and marks the item `pending` (B1). Most assignments lie outside that first page, but the page counts are not a measured DELETE failure rate. The 9 assigned groups with empty reference lists are consistent with failed unassignment; the audit does not establish the history of each one.

Other paths leave different inconsistencies. DELETE can return 200 without removing a key when the group is already unassigned (B3). PUT accepts malformed IDs and records a new reference before Graph succeeds, so rejected assignments leave data behind (B2).

| Group state at the audit snapshot      | Count | Significance                                                                                                            |
| -------------------------------------- | ----- | ----------------------------------------------------------------------------------------------------------------------- |
| Assigned, with references              | 455   | The assignment and reference presence agree; this does not prove every reference is current.                            |
| Assigned, with an empty reference list | 9     | Candidates for unassignment after access review.                                                                        |
| Assigned, with no table item           | 5     | Possibly managed outside the API; their purpose must be confirmed, not treated as automatic cleanup.                    |
| Referenced, but not assigned           | 219   | The audit identifies 211 deleted Entra groups and 8 non-GUID values. Reassignment is not an appropriate blanket repair. |

These states require different remedies. Obsolete references need client or inventory validation; unwanted assignments need access review; invalid and deleted groups need input correction and approved cleanup. A single "synchronize everything" operation would not safely resolve them.

The table's `syncState` field does not explain these differences (B6). A fast path that trusts `synced` needs a defined meaning for that value and a way to detect subsequent drift.

### Authentication does not limit what a caller may change

API Gateway requires IAM authentication, but its resource policy admits roles matching `arn:aws:iam::*:role/fleet-group-access-api*` across the Aster organization. The handler does not limit a caller to its own keys. An admitted cluster can remove another cluster's references; for a group with no table item, any DELETE key can trigger unassignment (S1).

Five assigned groups currently have no item, including `Fleet-Operations-Admin`. Their assignments may be intentional. Protecting only tracked references would not protect these groups unless the no-item deletion branch is removed. The broader exposure to accounts outside Fleet depends on whether service control policies prevent them from creating an admitted role; the audit could not verify that control.

The Aster-K8S credential creates an independent route around API authorization. Its secret and KMS policies extend access across three organizational unit paths and two more accounts. Principals able to obtain this broadly privileged Graph credential can change assignments without calling the API (S2). The identities and effective permissions covered by the sharing policies still need to be mapped.

### Deployment and monitoring do not provide adequate safeguards

There are no alarms or dashboards for the service (R2). This establishes a monitoring gap, not that nobody has noticed the failures. The audit reports no owner and found no runbook or on-call integration; responsibility for remediation and ongoing operation needs confirmation (D5).

The pipeline automatically deploys `delivery-test` and then `delivery-prod`. The only test is a placeholder, there is no pull-request build validation, and there is no manual production deployment gate (D2). With no client traffic, the `delivery-test` stage does not exercise real client workflows. Worse, it uses the production enterprise application and credential, so simply introducing tests against that deployment could change production access (S5).

## Recommended response

The original plan places handler repairs in phase 0 (days) and full caller authorization and credential isolation in phase 1 (weeks). This revision proposes reviewing security containment alongside the first repairs, rather than treating that delay as settled. It does not establish that all containment work can ship immediately. Owners need to decide the sequence and any accepted interim exposure.

### Contain access changes and establish responsibility

These actions address the current security exposure. Their rollout needs a named owner and approval; the audit does not establish who can authorize changes to the API, the shared credential, or existing assignments.

1. **Prevent deletion of groups the API does not track.** Remove the DELETE branch at `access-handler.ts:106-115`. Confirm the intended owners of the five untracked groups and preserve their assignments. This closes one deletion path, not all of S1.
2. **Limit callers to their own references.** Validate the mapping from caller roles `fleet-group-access-api-<cluster>` and `-tf-<cluster>` to permitted key prefixes, including legacy keys. Then enforce it in the handler and restrict the resource policy to the required Fleet organizational unit paths. Verify the service control policy coverage. If this cannot ship with the first repair, record the remaining exposure and obtain explicit acceptance of the delay.
3. **Restrict credentials and permissions.** Coordinate with `fleet-infrastructure` to identify legitimate readers of the Aster-K8S secret and establish a dedicated API credential. Scope the Lambda role to `GetSecretValue` for the required secret and `kms:Decrypt` for its key, removing `kms:*` and unused DynamoDB permissions (S2, S3). An API-only change cannot contain direct use of the shared credential.
4. **Stop logging raw requests and protect the rollout.** Log method, path parameters, caller ARN, and outcome without authentication headers (S4). Review access to retained sensitive logs. Add a production approval step and use isolated or mocked dependencies for tests; do not use the current `delivery-test` Graph configuration as a safe test target (D2, S5).

The original audit proposed adding static reference keys to the five untracked groups as an interim mitigation. That would remove their no-item state, but callers can currently delete keys they do not own. Static keys alone are therefore not sufficient protection. Any interim data change needs the groups' owners, approval, and an explicit assessment of what it prevents.

### Stabilize request handling and deletion

1. **Avoid external calls for unchanged reference state.** For PUT, answer from DynamoDB when the key exists and the item has a trustworthy `synced` state. For DELETE, return 200 when the key is already absent, without changing Entra. The expected latency improvement is substantial, but must be measured under representative traffic. These responses no longer check or repair assignment drift; define how drift will be detected before relying on them.
2. **Repair both DELETE defects.** Read all required assignment pages, or query `/groups/{id}/appRoleAssignments` and identify the assignment for this enterprise application. Preserve unrelated application assignments and handle pagination if present. Remove the requested reference even when the group is already unassigned (B1, B3).
3. **Validate input and define partial-failure behavior.** Reject malformed GUIDs with 400. The original audit proposes 422 when Graph cannot resolve the group; distinguish that condition from transient Graph or authentication failures. It also proposes writing new references only after Graph succeeds. That ordering avoids one inconsistency but can leave an assignment without a recorded reference if the database write fails. Specify retry, recovery, and response behavior for both systems rather than treating ordering alone as a complete fix (B2).
4. **Reduce remaining overhead and detect failures.** Cache the secret and Graph credential at module scope, with bounded refresh on authentication failure to support weekly rotation. Evaluate the proposed increase to 512 MB. Add alarms for 5xx rate, throttles, and handler errors, routed to a confirmed responder. Enable DynamoDB deletion protection alongside the existing point-in-time recovery and retention policy (R2, R4, R5).

Keep the first changes small enough to test and roll back independently. Focused tests should cover unchanged PUT and DELETE requests making no Secrets Manager or Graph calls; rejection of cross-caller keys; preservation of untracked groups; deletion beyond the first assignment page; reference removal when the group is already unassigned; and partial failures between Graph and DynamoDB. Add CDK assertions for the security and infrastructure controls.

Before rollout, agree on acceptable error and throttle rates and compare them with the audit baseline. Successful deletion must mean the key was removed and, where appropriate, the final assignment was removed; HTTP 200 alone is not sufficient evidence. Do not assume increasing reserved concurrency is safe until concurrent reference updates have been checked.

### Recover state and make the service maintainable

Establish a scheduled comparison of references and assignments. Initially report discrepancies for review. Automatic assignment repair should apply only to valid, confirmed API-managed groups with current references; do not try to recreate deleted groups or interpret arbitrary strings as group IDs. Unassignment remains subject to access review. Decide whether this process must be available when the fast path ships or whether a temporary review process is adequate.

Seek approval to clean up invalid and deleted-group items and assignments with empty reference lists. Validate clusters absent from the fleet catalog before deleting their references: inventory absence alone does not establish that a cluster no longer exists. Counts and classifications are recorded below.

In `fleet-infrastructure`, send PUTs only when the group set changes and retry transient failures with backoff, including DELETEs. Give the API an Entra identity that owns only `fleet-k8s-login`, restrict its credential to the Lambda role, and review Aster-K8S sharing and retired permissions with that repository's maintainers.

Move builds to an Amazon Linux 2023 image, upgrade dependencies, replace the old `LogRetention` function as needed, and add pull-request build validation. Isolate the non-production Entra application and credential before directing feature-branch clients or integration tests there. Confirm an operating owner, on-call routing, and a runbook covering failed deletion and reconciliation.

### Replace the per-key contract

Use `fleet-access-operator` ADR-007 as the basis for API v2: full-state sources per cluster, conditional writes, GET, and caller-scoped source IDs. A migration should remove the namespace-colliding RoleBinding keys and reduce repeated per-key traffic. Retire v1 clients only after their references and ownership have been accounted for. This is longer-term contract work, not a substitute for containing v1's current exposure.

## Finding register

This register retains the original IDs and ratings for tracking. Ratings describe the original audit's assessment of impact on fleet access and the Entra tenant; they have not been independently reassessed. The explanations and response sequence above connect the findings. Source paths below refer to the audited API repository unless another repository is named.

### Security

**S1 - Critical. Callers can remove other clusters' references and untracked assignments.** Organization-wide role-name matching admits callers without per-key ownership checks. The no-item DELETE branch can unassign externally managed groups. Exposure to new roles outside Fleet depends on unverified service control policies. Sources: `infra/stacks/access-api-stack.ts:146-165`, `service/src/access-handler.ts:50-241`, and `access-handler.ts:106-115`.

**S2 - High. The shared Entra credential bypasses API authorization.** Secret `fleet_directory_client` and its KMS key share access across three organizational unit paths and two additional accounts. Aster-K8S holds `Application.ReadWrite.OwnedBy` over 392 owned objects, including `fleet-k8s-login`, plus `Directory.Read.All`, `Group.Create`, and two retired Azure AD Graph permissions. Secret sharing and weekly rotation belong to `fleet-infrastructure`; effective readers need to be identified.

**S3 - High. The Lambda role has unnecessarily broad secret and KMS permissions.** Its identity policy grants `secretsmanager:GetSecretValue` and `kms:*` on `*` in account `111111111111`. Actual resource access also depends on resource policies and other controls. The bundle includes `@azure/identity` and `@azure/msal-node` with locked dependencies carrying `jws` and `uuid` advisories. Source: `access-api-stack.ts:133-139`.

**S4 - Medium. Authentication headers are written to logs.** The raw API Gateway event includes `X-Amz-Security-Token`, `Authorization`, and caller identity. The audit found 58,207 such log events in 24 hours. The handler log group holds 6 GB with 30-day retention; access is available to principals with the relevant CloudWatch Logs read permissions in `delivery-prod`. Source: `access-handler.ts:51`.

**S5 - Medium. Non-production deployments target production access state.** `delivery-test` and `STAGE=<name>` deployments use the production application ID and secret ARN. Feature-branch clusters also use the production endpoint; the inventory comparison includes 37 feature-branch clusters. Confirm their lifecycle state before cleanup. Sources: `access-handler.ts:41,417` and the client/inventory evidence.

**S6 - Low. Error responses expose internal details.** Graph and SDK error text is returned in HTTP 500 bodies. Return a stable external error and retain diagnostic detail in appropriately restricted logs. Source: `access-handler.ts:248-255`.

### Correctness

**B1 - High. Final-reference deletion misses assignments beyond the first page.** `removeGroupAssignment` reads only one page of `appRoleAssignedTo`. The snapshot has 50 assignments on the first page out of 472 total; roughly 89 percent lie beyond it. This establishes the paging defect's reach, not an observed per-request failure percentage. Source: `access-handler.ts:373-386`.

**B2 - High. Invalid input and failed assignments leave persistent references.** New PUTs write before Graph succeeds, and group IDs are not validated as GUIDs. Stale `identity.fleet.example/team-group-id` labels and Group subjects such as `system:authenticated` supply invalid or deleted groups. The audit attributes about 1,300 handler 500s per day to these cases. Source: `access-handler.ts:164-177`.

**B3 - Medium. DELETE can acknowledge a key it has not removed.** An existing item with an unassigned group reaches no matching deletion branch and returns 200 without removing the key. Source: `access-handler.ts:99-158`.

**B4 - Medium. RoleBinding references collide across namespaces.** `<cluster>-rb-<name>` identifies multiple bindings as one reference. Deleting one can remove the shared reference while another binding still needs the group. The client defect is discussed in `fleet-access-operator` ADR-007.

**B5 - Low. Duplicate-assignment errors escape handling.** Twelve "EntitlementGrant entry already exists" errors escaped the catch in three days. An `instanceof GraphError` mismatch in the bundle is a hypothesis, not a verified cause. Source: `access-handler.ts:344-355`.

**B6 - Low. Synchronization status does not explain failures.** Of the items with references, 163 are `pending`, mostly for deleted groups. The field alone does not distinguish recoverable drift from invalid references, and the audit does not establish whether `synced` reliably implies a current assignment.

### Reliability and performance

**R1 - Critical. Request failures prevent reliable reference updates.** Reserved concurrency is 1, and unchanged requests still perform secret, token, and assignment-listing work. The original audit estimates a 55 percent rejection rate from about 1.5 requests per second and 0.81 seconds per call. This is a capacity prediction, not a measured rejection rate; HTTP failures and Lambda throttles are recorded separately below. Sources: `access-api-stack.ts:101` and `access-handler.ts:53-88,291-318`.

**R2 - High. Failures have no configured alerting.** No alarms or dashboards were found. Whether responders already knew about the failure rate is not established by that absence.

**R3 - Medium. Reference growth is bounded by a single-item limit.** The largest item contains 3,468 references and occupies about 134 KB of DynamoDB's 400 KB limit. The original estimate of failure near 10,000 references is approximate and depends on key sizes. References from clusters absent from inventory further consume capacity.

**R4 - Medium. The reference table lacks deletion protection.** Point-in-time recovery and `RETAIN` are enabled, but deletion protection is not. Recovery controls do not prevent table deletion.

**R5 - Low. Runtime, endpoint, and observability configuration need review.** Lambda uses 128 MB; the API is edge-optimized although callers are in `eu-central-1`; the default `execute-api` endpoint remains enabled beside the custom domain. API Gateway tracing is off while Lambda tracing is on. Access logs omit caller identity and have 7-day retention. The benefit of memory or endpoint changes needs measurement.

### Delivery and maintenance

**D1 - High. Builds use an Amazon Linux 2 image after OS end of support.** CodeBuild uses `AMAZON_LINUX_2_ARM_3`; the audit cites Amazon Linux 2 end of support on 2026-06-30. Confirm the managed CodeBuild image's support status separately when selecting its replacement. Source: `infra/stacks/delivery-stack.ts:73`.

**D2 - High. Automatic production deployment lacks meaningful validation.** The pipeline deploys `delivery-test` and then `delivery-prod`, with no manual production approval or pull-request build validation. The test is a placeholder and non-production has no callers. Azure DevOps project-wide reviewer policies exist; no pull requests were found in the repository history in `aster-fleet`. That history alone does not prove all changes bypassed review. Sources: `delivery-stack.ts:89-116`, `mirror-repository.yml`, and `infra/test/group-access-api.test.ts`.

**D3 - Medium. Dependencies and generated runtime resources need updating.** The audit reports dependencies about 17 months old and `aws-cdk-lib` 2.184.0 versus 2.258.0 at audit time. `npm audit` reports 26 production-tree advisories, including 1 critical and 4 high, and 59 total. The critical `fast-xml-parser` is under the AWS SDK, which is excluded from the Lambda bundle in favor of the runtime copy; the lockfile advisory does not establish the deployed copy's vulnerability. The CDK `LogRetention` custom resource runs on `nodejs20.x`.

**D4 - Medium. Hardcoded configuration and misleading documentation increase change risk.** Tenant, application, secret, and account identifiers are hardcoded; TODOs and debug output remain. `docs/api/openapi.json` is empty. The design describes synchronous namespace validation that clients do not perform, and the Postman collection targets production despite its README saying non-production. Sources: `access-handler.ts:41,58,390,417`, `delivery-stack.ts`, `access-api-stack.ts:169`, and `docs/design/access-claims.md`.

**D5 - Medium. Operational ownership needs confirmation.** The audit reports no owner and found no runbook or on-call integration. The last functional change was March 2025. The repository also lacks `AGENTS.md`, but that absence does not establish a lack of ownership. Obtain a named team's confirmation of responsibility.

## Supporting measurements

### Traffic and execution

| Measurement                                    | Audit result                                                                                                                      |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Requests over 24 hours                         | About 128,400: 56,400 returned 200, 71,928 returned 500, and 72 returned 403. Counts are reported at different precisions.        |
| Requests over 30 days                          | 3.54 million; 2.01 million returned 5xx.                                                                                          |
| Lambda throttles over 30 days                  | 1.93 million; daily peak 76,540. These are distinct from HTTP response counts.                                                    |
| Handler errors over 3 days                     | 3,786 "Invalid reference transition" errors attributed to deleted groups; 27 for `authenticated`; 12 duplicate-assignment errors. |
| Latency                                        | p50 809 ms; p99 1,784 ms.                                                                                                         |
| Caller accounts over 24 hours                  | 72, including callers for the Cedar clusters; account count is not cluster count.                                                 |
| Distinct request keys and groups over 24 hours | 1,479 keys and 352 groups; about 87 requests per key on average, with the busiest key sent every 20 seconds.                      |

### Reference data and deployment

| Measurement                                            | Audit result                                                                                                                                     |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Production reference table                             | 683 group items and 9,274 references: 7,910 namespace, 1,196 RoleBinding, and 168 Terraform references.                                          |
| Largest group item                                     | 3,468 references; about 134 KB of the 400 KB item limit.                                                                                         |
| Entra assignments                                      | 472: 469 groups, 1 user, and 2 service principals. Graph returns 50 per page. Group/reference discrepancies are listed in the main report.       |
| Non-GUID reference items                               | 8, including `NOT-A-GROUP`, `unknown`, `authenticated`, and typos. The group-state table above records all 219 referenced but unassigned groups. |
| Deleted groups still referenced by live clusters       | 197.                                                                                                                                             |
| Clusters with references but absent from fleet catalog | 51, classified by the audit as 37 feature-branch and 14 decommissioned. Existence and cleanup eligibility need confirmation.                     |
| Deployed code / latest pipeline run                    | 2025-03-12 / 2026-08-03.                                                                                                                         |
| Non-production reference table                         | 0 items in `delivery-test`; the audit reports no callers.                                                                                        |

## Evidence sources

| Evidence area                         | Source recorded by the audit                                                                                                                                    |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Handler, infrastructure, and pipeline | `service/src/access-handler.ts`, `infra/stacks/access-api-stack.ts`, `infra/stacks/delivery-stack.ts`, and `mirror-repository.yml`.                             |
| Traffic and errors                    | CloudWatch `AWS/Lambda` and `AWS/ApiGateway` metrics over 30 days; Logs Insights over 1-3 days for the handler log group and `/fleet/apigw/group-access-api`.   |
| Reference data                        | Aggregated DynamoDB scan of `groupClaimReferences-group-access-api`.                                                                                            |
| Entra state                           | Graph queries for `fleet-k8s-login` assignments and claim settings, Aster-K8S permissions and ownership, and `directoryObjects/getByIds` existence checks.      |
| Credential access                     | Secrets Manager metadata and resource policy, KMS key policy, and 7 days of CloudTrail `GetSecretValue` events.                                                 |
| Clients                               | `fleet-infrastructure/controllers/access-controller/src/reconcile.ts` and `fleet-infrastructure/terraform/providers/fleet-access/internal/namespace_admins.go`. |
| Cluster inventory                     | `fleet-catalog/config/clusters.yaml`, containing 76 clusters.                                                                                                   |
| OS support                            | Amazon Linux 2 FAQ, citing end of support on 2026-06-30.                                                                                                        |
