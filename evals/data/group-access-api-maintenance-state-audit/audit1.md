# Group Access API Audit

**Date:** 2026-08-18  
**Scope:** this repository at `7c4e2a1`, the deployed stacks in `delivery-prod`
(`111111111111`) and `delivery-test` (`222222222222`), the Entra objects the API
changes, and the legacy clients in `cloud-services/fleet-infrastructure`.  
**Method:** source review, `npm audit`, and read-only queries of
API Gateway, Lambda, DynamoDB, CloudWatch metrics and Logs Insights,
CloudTrail, Secrets Manager and KMS metadata, Microsoft Graph, and Azure
DevOps. Nothing was changed. Group IDs are not reproduced here.

## Summary

The API decides which Entra groups appear in the `groups` claim that every
self-managed Kubernetes cluster in the fleet uses for access (72 caller
accounts per day, including the Cedar clusters). It is unowned and in poor health:

- **It rejects most of its traffic.** In the last 24 hours it received
  128,400 requests and returned 500 for 71,928 (56 percent). Over 30 days
  Lambda recorded 1.93 million throttles. The cause is one Lambda execution
  at a time, about 0.81 seconds per call, and clients that resend unchanged
  state constantly. The legacy clients never retry, so failed DELETEs are
  lost for good.
- **Any caller can remove any group from the fleet's token claim**,
  including groups the API never registered. One of those is
  `Fleet-Operations-Admin`. Callers are authorized by role name pattern
  across the whole Aster organization, and the handler never checks which keys
  a caller owns.
- **Group removal is broken.** The last-reference DELETE inspects only the
  first page of assignments: 50 of 472. Nine groups are assigned with no
  references.
- **The Entra credential behind the API is readable across three organizational units and two further accounts**,
  so the API is not the real boundary around the Entra application.
- **Production changes ship without a gate** from a pipeline built on Amazon
  Linux 2, which reached end of support on 2026-06-30. Tests are a
  placeholder and nothing alerts.

Most of the operational damage can be removed with one small handler
change: answer unchanged PUT and DELETE requests from DynamoDB without
calling Secrets Manager or Graph (finding R1). The security findings need
the authorization and credential changes in phase 1.

## What the API does

```
cluster role fleet-group-access-api-<cluster>  --SigV4-->  API Gateway (IAM auth, resource policy)
  PUT|DELETE /v1/{groupId}/{key}                              |
                                                              v
                Lambda (reserved concurrency 1) -- Secrets Manager: Aster-K8S client secret
                    |                         \-- Microsoft Graph as Aster-K8S:
                    v                              assign or unassign the group on
          DynamoDB: one item per group,                 enterprise app fleet-k8s-login
          list of keys referencing it
```

`fleet-k8s-login` has `groupMembershipClaims: ApplicationGroup`, so tokens
carry only groups assigned to it. The clusters run on EC2; their Kubernetes
API servers validate these OIDC tokens and map the groups to
`entra:<groupId>` for RBAC. One assignment applies to the whole fleet.

Callers are the legacy access-controller (keys `<cluster>-ns-<namespace>`
and `<cluster>-rb-<rolebinding>`) and a Terraform provider (key
`<cluster>-tf-namespace-admins`), both in `fleet-infrastructure`.

## Live State

| Measure                                                    | Value                                                                                                                  |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Requests, last 24 h                                        | 128,400: 56,400 succeeded (200), 71,928 failed (500), 72 rejected (403)                                                |
| Requests, last 30 d                                        | 3.54 M; 2.01 M returned 5xx                                                                                            |
| Lambda throttles, last 30 d                                | 1.93 M (peak 76,540 in one day)                                                                                        |
| Handler errors, last 3 d                                   | 3,786 "Invalid reference transition" (deleted groups), 27 for group `authenticated`, 12 duplicate assignment         |
| Latency                                                    | p50 809 ms, p99 1,784 ms, 128 MB memory                                                                                |
| Caller accounts, last 24 h                                 | 72                                                                                                                     |
| Distinct keys and groups, last 24 h                        | 1,479 keys and 352 groups across 128,400 requests: each key is sent about 87 times a day, the busiest every 20 seconds |
| Reference table (prod)                                     | 683 groups, 9,274 references (7,910 namespace, 1,196 RoleBinding, 168 Terraform)                                      |
| Largest item                                               | 3,468 references, about 134 KB of the 400 KB item limit                                                                |
| Entra assignments                                          | 472 (469 groups, 1 user, 2 service principals); Graph returns 50 per page                                              |
| Assigned and referenced                                    | 455 groups                                                                                                             |
| Assigned with zero references                              | 9 groups                                                                                                               |
| Assigned with no item at all                               | 5 groups, including `Fleet-Operations-Admin`                                                                            |
| Referenced but not assigned                                | 219 groups: 211 deleted from Entra, 8 not GUIDs (`NOT-A-GROUP`, `unknown`, `authenticated`, and typos)                 |
| Deleted groups still referenced by live clusters           | 197                                                                                                                    |
| Clusters with references that are not in the fleet catalog | 51 (37 feature-branch, 14 decommissioned)                                                                              |
| Deployed code                                              | 2025-03-12; pipeline last ran 2026-08-03                                                                               |
| Non-prod table (`delivery-test`)                           | 0 items: the `delivery-test` instance has no callers                                                                   |
| Alarms                                                     | none                                                                                                                   |

## Findings

Severity reflects impact on fleet access and on the Entra tenant.

### Security

**S1 Critical: any caller can revoke any group fleet-wide, including groups the API never registered.**

- The resource policy admits any role whose ARN matches
  `arn:aws:iam::*:role/fleet-group-access-api*` in any account of the Aster
  organization (`infra/stacks/access-api-stack.ts:146-165`). Any account
  administrator in the organization can create such a role unless a service
  control policy prevents it; that was not verifiable from these accounts.
- The handler never compares the caller with the key it changes
  (`service/src/access-handler.ts:50-241`), so one cluster can remove another cluster's
  references.
- A DELETE for a group with no table item, but assigned in Entra, unassigns
  that group whatever key is sent (`access-handler.ts:106-115`). Five groups are in
  that state today, including `Fleet-Operations-Admin`. One unauthenticated
  mistake or a hostile call removes those groups from every token.

**S2 High: the Entra credential is readable far beyond the API.**

- Secret `fleet_directory_client` (the Aster-K8S client secret) allows
  `GetSecretValue` to any principal in three organizational unit paths and
  two more accounts. Its KMS key policy allows `kms:Decrypt` to the same set.
- Aster-K8S holds Graph `Application.ReadWrite.OwnedBy` over 392 owned objects
  (including `fleet-k8s-login`), `Directory.Read.All` and `Group.Create`.
  It also holds two permissions on the retired Azure AD Graph API.
- Anyone who can read that secret can change the fleet's group assignments
  directly, so IAM on this API does not protect the Entra application.
- The secret, its rotation (weekly, from `fleet-infrastructure`) and its
  sharing belong to `fleet-infrastructure`; fixing it needs that repository.

**S3 High: the Lambda role can read every secret and use every KMS key in the pipeline account.**
It grants `secretsmanager:GetSecretValue` and
`kms:*` on `*` in `111111111111` (`access-api-stack.ts:133-139`). A
compromised dependency would reach every secret in that account. The bundle
includes `@azure/identity` and `@azure/msal-node`, whose locked versions
carry advisories (`jws`, `uuid`).

**S4 Medium: request credentials are logged.** The handler logs the whole
API Gateway event (`access-handler.ts:51`). In 24 hours, 58,207 log events contained
the caller's `X-Amz-Security-Token`, along with the `Authorization` header
and caller identity. The log group holds 6 GB with 30-day retention, readable
by anyone with CloudWatch Logs read access in `delivery-prod`.

**S5 Medium: test instances change production access.**

- The `delivery-test` stage and any `STAGE=<name>` deployment use the production
  enterprise application ID and the production secret ARN (`access-handler.ts:41,417`).
- Feature-branch clusters call the production endpoint and have left
  references from 37 clusters that no longer exist.

**S6 Low: internal errors are returned to callers.** Graph and SDK error text
goes into the 500 body (`access-handler.ts:248-255`).

### Correctness

**B1 High: last-reference DELETE does not unassign most groups.**
`removeGroupAssignment` reads one page of `appRoleAssignedTo`
(`access-handler.ts:373-386`). Graph returns 50 per page and there are 472
assignments. For about 89 percent of groups the API marks the item
`pending` and leaves the assignment. 9 such groups exist today. Stale
assignments are what eventually push heavy users back over the 200-group
claim limit this API exists to avoid (`docs/design/access-claims.md`).

**B2 High: invalid and deleted groups become permanent errors.**

- There is no GUID validation.
- A PUT for a new group writes the table item before calling Graph
  (`access-handler.ts:164-177`), so a failed assignment leaves a reference behind.
- Result: 8 non-GUID items, 211 items for deleted groups, and about 1,300
  handler 500s a day.
- The client-side cause is stale `identity.fleet.example/team-group-id` labels and Group subjects
  such as `system:authenticated`.

**B3 Medium: DELETE can silently keep a reference.** When the item exists
but the group is unassigned, no branch matches and the API returns 200
without removing the key (`access-handler.ts:99-158`).

**B4 Medium: RoleBinding keys are shared across namespaces.** The legacy
client's `<cluster>-rb-<name>` key drops the namespace, so one deletion
removes the reference for every namespace using that RoleBinding name. This
is a client defect, but it corrupts the table's reference counts (see
`fleet-access-operator` ADR-007).

**B5 Low: duplicate-assignment handling is fragile.** 12 "EntitlementGrant
entry already exists" errors in three days escaped the catch at
`access-handler.ts:344-355`. The likely cause is an `instanceof GraphError` mismatch
in the bundle.

**B6 Low: `syncState` carries no reliable meaning.** 163 items with live
references are `pending`, mostly deleted groups.

### Reliability and performance

**R1 Critical: the API rejects more than half of its traffic.**

- Reserved concurrency 1 (`access-api-stack.ts:101`) makes the API a
  single server with no queue. At 1.5 requests per second and 0.81 seconds
  each, the expected rejection rate is about 55 percent; 56 percent is
  observed.
- Each call fetches the secret, acquires an Entra token, and pages through
  all 472 assignments (about ten Graph pages), even when nothing changes
  (`access-handler.ts:53-88, 291-318`).
- The volume comes from clients resending unchanged state: about 87 requests
  per key per day.
- The legacy clients do not retry. Failed PUTs only succeed because the same
  state is resent minutes later. Failed DELETEs are lost permanently, which is
  a main source of stale references.

**R2 High: nothing alerts.** There are no alarms or dashboards. The failure
rate above has gone unnoticed for at least 30 days.

**R3 Medium: the reference model does not scale.**

- The busiest group's item is 134 KB, about a third of DynamoDB's 400 KB
  item limit. Past roughly 10,000 references, every PUT for that group fails.
- References from 51 nonexistent clusters are never removed.

**R4 Medium: the only copy of the access reference state has no deletion protection.**
Point-in-time recovery and `RETAIN` are set, but deletion
protection is off.

**R5 Low: configuration.**

- 128 MB memory slows Node and TLS work.
- The REST API is edge-optimized although all callers are in `eu-central-1`.
- The default `execute-api` endpoint stays enabled next to the custom domain.
- API Gateway tracing is off while Lambda tracing is on.
- Access logs do not record the caller identity and are kept 7 days.

### Delivery and maintenance

**D1 High: the pipeline builds on an unsupported OS.** CodeBuild uses
`AMAZON_LINUX_2_ARM_3` (`infra/stacks/delivery-stack.ts:73`). Amazon Linux 2
reached end of support on 2026-06-30.

**D2 High: a merge reaches production with no gate.**

- `main` is mirrored to CodeCommit and the CDK pipeline deploys `delivery-test` and
  then `delivery-prod` automatically (`delivery-stack.ts:89-116`, `mirror-repository.yml`).
- The `delivery-test` instance has no callers, so that stage validates nothing.
- The only test is a placeholder (`infra/test/group-access-api.test.ts`).
- Azure DevOps applies project-wide reviewer policies, but there is no build
  validation and no pull request exists in the repository's history in
  `aster-fleet`.

**D3 Medium: dependencies are 17 months old.**

- `aws-cdk-lib` is 2.184.0; the latest is 2.258.0.
- `npm audit` reports 26 advisories in the production dependency tree
  (1 critical, 4 high) and 59 in total. The critical `fast-xml-parser` sits
  under the AWS SDK, which the Lambda bundle leaves out in favor of the
  runtime copy.
- The CDK `LogRetention` custom resource runs on `nodejs20.x`.

**D4 Medium: hardcoded values and stale documentation.**

- Hardcoded tenant ID, enterprise application ID, secret ARN and account IDs
  (`access-handler.ts:41,58,417`; `delivery-stack.ts`; `access-api-stack.ts:169`),
  plus open TODOs and debug output (`access-handler.ts:390`).
- `docs/api/openapi.json` is empty.
- `access-claims.md` describes synchronous namespace validation that no client
  performs.
- The Postman README says the collection targets non-prod; it targets prod.

**D5 Medium: no owner.** The last functional change was March 2025. The
repository has no `AGENTS.md`, runbook, or on-call integration.

## Improvement Plan

### Phase 0: stop the damage (days)

One handler pull request plus configuration:

1. Answer from DynamoDB first.
   - PUT: if the key is already present and the item is synced, return 200
     without calling Secrets Manager or Graph.
   - DELETE: if the key is absent, return 200.
  - Expected effect: most requests drop from about 810 ms to tens of
     milliseconds, which removes most throttling at concurrency 1. Repair of
     missing assignments moves to the reconciliation job in phase 1.
2. Never unassign a group the table does not track. Delete the branch at
  `access-handler.ts:106-115`.
3. Fix delete paging. Better still, read the group's own assignments
  (`/groups/{id}/appRoleAssignments`) instead of listing all 472.
4. Validate the group ID as a GUID and return 400. Return 422 for a group
   Graph cannot resolve, and write the table only after Graph succeeds.
5. Log method, path parameters, caller ARN and outcome. Stop logging the raw
   event.
6. Cache the secret and Graph credential at module scope. Refresh on
   authentication failure, since the secret rotates weekly.
7. Raise Lambda memory to 512 MB.
8. Add alarms on 5xx rate, throttles and handler errors, routed to on-call.
9. Enable deletion protection on the table.

Interim data mitigation, needs approval because it writes production data:
register the five untracked groups under explicit static keys, so
DELETE cannot remove them before item 2 ships.

### Phase 1: secure and operable (weeks)

1. **Caller authorization.**
   - Map caller role `fleet-group-access-api-<cluster>` (and
     `-tf-<cluster>`) to the only key prefix that caller may change.
   - Restrict the resource policy to the Fleet organizational unit paths
     instead of the whole organization.
   - Check for a service control policy covering the role name.
2. **Least privilege.** Grant the Lambda `GetSecretValue` on one secret and
   `kms:Decrypt` on one key. Remove `kms:*` and unused DynamoDB actions.
3. **Dedicated credential, with `fleet-infrastructure`.**
   - Give the API its own Entra application that owns only
     `fleet-k8s-login`, with a credential readable only by the API's Lambda
     role.
   - Remove the retired Azure AD Graph permissions from Aster-K8S.
   - Review who needs the shared Aster-K8S secret across organizational units.
4. **Pipeline.**
   - Amazon Linux 2023 build image.
   - Handler unit tests with mocked Graph and DynamoDB, plus CDK assertions.
   - Build validation on pull requests.
  - Manual approval before `delivery-prod`.
   - Dependency upgrades, which also replace the `LogRetention` function.
5. **Non-production isolation.** Point the `delivery-test` stage and feature
   deployments at a test Entra application, or remove them. Feature-branch
   clusters use the non-prod endpoint.
6. **Reconciliation job.**
   - Report assigned versus referenced groups on a schedule.
   - Repair missing assignments automatically.
   - Unassignment only after access review.
7. **Approved data cleanup.**
  - References from the 51 nonexistent clusters.
  - 8 invalid items and 211 deleted-group items.
  - The 9 stale assignments, after review.
8. **Client-side volume reduction** in `fleet-infrastructure`: the legacy
  access-controller sends a PUT only when the group set changes, and
   retries with backoff.

### Phase 2: replace the contract (months)

Implement API v2 from `fleet-access-operator` ADR-007:

- full-state sources per cluster,
- conditional writes, GET, and caller-scoped source IDs,
- then retire the per-key v1 clients.

This removes the shared RoleBinding keys and reduces fleet traffic to one
request per cluster per change.

## Open Verification Items

- Whether a service control policy stops accounts outside Fleet from creating
  `fleet-group-access-api*` roles. This decides whether S1 can be
  exploited from outside the platform.
- Which accounts the three organizational unit paths and two account IDs in
  the secret and KMS policies represent.
- The exact cause of the 12 escaped duplicate-assignment errors.
- Who intended `Fleet-Operations-Admin`, `Cloud-Audit-Readers`,
  `Service-Reporting-Access`, `Build-System-Operators` and `Incident-Response`
  to be assigned outside the API.

## Evidence Sources

| Area                              | Source                                                                                                                                                |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Handler, infrastructure, pipeline | `service/src/access-handler.ts`, `infra/stacks/access-api-stack.ts`, `infra/stacks/delivery-stack.ts`, `mirror-repository.yml`                        |
| Traffic and errors                | CloudWatch `AWS/Lambda` and `AWS/ApiGateway` metrics (30 d); Logs Insights on the handler log group and `/fleet/apigw/group-access-api` (1 to 3 d)    |
| Data                              | DynamoDB scan of `groupClaimReferences-group-access-api`, aggregated                                                                                |
| Entra                             | Graph: `fleet-k8s-login` assignments and claim setting; Aster-K8S permissions and ownership; `directoryObjects/getByIds` for existence                 |
| Secret                            | Secrets Manager metadata and resource policy, KMS key policy, CloudTrail `GetSecretValue` (7 d)                                                       |
| Clients                           | `fleet-infrastructure/controllers/access-controller/src/reconcile.ts`, `fleet-infrastructure/terraform/providers/fleet-access/internal/namespace_admins.go` |
| Inventory                         | `fleet-catalog/config/clusters.yaml` (76 clusters)                                                                                                   |
| Platform support                  | Amazon Linux 2 FAQ: end of support 2026-06-30                                                                                                         |
