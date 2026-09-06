# AWS Policy Guardrails

AWS policy examples address organization-level restrictions and delegated IAM permissions.

## Contents

- `iam/permission-boundaries/developer_boundary.json`: limits a developer role to approved services and denies common escalation paths
- `iam/privilege-escalation/privilege_escalation_paths.md`: review guide for high-risk IAM combinations
- `scps/`: service control policies for root use, organization departure, CloudTrail changes, public S3 configuration, IMDSv1, and non-approved Regions
- [`scps/scp_deployment.md`](scps/scp_deployment.md): staged deployment guidance

## Review workflow

1. Parse and lint the JSON.
2. Confirm every action, resource, condition, exception, and `NotAction` behavior.
3. Test with IAM simulation where supported.
4. Attach first to a non-production organizational unit with break-glass access.
5. Verify allowed and denied operations before broader rollout.

SCPs limit maximum permissions; they do not grant access. Permission boundaries also do not grant permissions. Effective access depends on the complete identity, resource-policy, session-policy, boundary, and organization-policy evaluation.
