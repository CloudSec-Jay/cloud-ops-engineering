# Permission Boundary: Developer Sandbox

**File:** `developer_boundary.json`
**Type:** IAM Permission Boundary
**Attach to:** All developer IAM roles
**MITRE:** T1548.005 — Abuse Elevation Control Mechanism
**NIST:** AC-6 (Zero Trust), AC-3 (Access Enforcement)
**CIS:** 5.4 — Restrict Administrator Privileges
**OWASP:** A01:2021 — Broken Access Control

---

## What Is a Permission Boundary?

A permission boundary is a policy attached to an IAM role or user that defines the **maximum permissions that identity can ever have**. It is not a grant — it is a ceiling.

```
Effective permissions = Identity Policy AND Boundary

Both must allow the action. Either one blocking it = denied.
```

If a developer's identity policy allows `iam:AttachRolePolicy` but the boundary does not — the action is denied. The boundary wins.

---

## What This Boundary Allows

### `AllowApprovedServices`

```json
"Action": [
    "ec2:Describe*", "ec2:Get*",
    "s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject",
    "lambda:CreateFunction", "lambda:UpdateFunctionCode", ...
    "logs:*", "cloudwatch:*",
    "ssm:GetParameter*",
    "tag:*"
]
```

The approved service list for a developer working on serverless/compute workloads. Read EC2, read/write S3, full Lambda lifecycle, CloudWatch logs, SSM parameter reads, tagging.

`Resource: *` is acceptable here because this is the boundary layer — the identity policy underneath should further restrict resources. The boundary sets the outer limit; the identity policy scopes within it.

---

### `AllowPassRoleToApprovedServicesOnly`

```json
"Action": "iam:PassRole",
"Condition": {
    "StringEquals": {
        "iam:PassedToService": ["lambda.amazonaws.com", "ec2.amazonaws.com"]
    }
}
```

`iam:PassRole` is required for developers to attach roles to Lambda functions and EC2 instances. Without it they cannot do their job.

The condition scopes it: the role can only be passed to Lambda and EC2 service principals — not to Glue, CloudFormation, or other services used in escalation paths 11, 12, 13 from `privilege_escalation_paths.md`.

This closes **Path 1** (PassRole + Lambda) when combined with identity policy resource scoping on which role ARNs can be passed.

---

### `AllowCreateRoleWithBoundaryOnly`

```json
"Action": ["iam:CreateRole", "iam:PutRolePolicy", "iam:AttachRolePolicy", ...],
"Condition": {
    "StringEquals": {
        "iam:PermissionsBoundary": "arn:aws:iam::${aws:PrincipalAccount}:policy/DeveloperBoundary"
    }
}
```

This is the key escalation prevention statement. Developers can create IAM roles — Lambda functions need execution roles. But they can **only** create roles that have this same boundary attached.

`${aws:PrincipalAccount}` is a policy variable that resolves to the account ID at evaluation time — no hardcoded account IDs needed.

**Why this matters:** Without this condition, a developer could create a role with no boundary, attach `AdministratorAccess` to it, then pass it to a Lambda. With this condition, every role they create is also capped by the developer boundary — they can never create a role more powerful than their own ceiling.

This closes **Paths 3, 4, 5** from `privilege_escalation_paths.md`.

---

### `AllowReadIAM`

Read-only IAM permissions — `GetRole`, `GetPolicy`, `ListRoles`, etc. Developers need to inspect roles and policies to build their applications. Read is safe; write is dangerous. This allows the former, everything else in `DenyEscalationPaths` blocks the latter.

---

## What This Boundary Denies

### `DenyEscalationPaths`

```json
"Action": [
    "iam:CreateUser", "iam:CreateAccessKey", "iam:UpdateAccessKey",
    "iam:CreateLoginProfile", "iam:UpdateLoginProfile",
    "iam:AttachUserPolicy", "iam:PutUserPolicy", "iam:AddUserToGroup",
    "iam:CreateGroup", "iam:AttachGroupPolicy", "iam:PutGroupPolicy",
    "iam:CreatePolicyVersion", "iam:SetDefaultPolicyVersion",
    "iam:DeletePolicy", "iam:UpdateAssumeRolePolicy",
    "organizations:*", "account:*"
]
```

Explicitly denies every IAM write action that maps to a privilege escalation path:

| Denied Action | Escalation path closed |
|--------------|----------------------|
| `iam:CreateUser` | Path 3, 6 — no users to attach policies to or add to groups |
| `iam:CreateAccessKey` | Path 7 — can't create keys for other users |
| `iam:CreateLoginProfile` | Path 8 — can't create console access for other users |
| `iam:UpdateLoginProfile` | Path 9 — can't reset passwords for other users |
| `iam:AttachUserPolicy` | Path 3 — can't attach AdministratorAccess to self |
| `iam:PutUserPolicy` | Path 5 — can't write inline policy granting `*:*` |
| `iam:AddUserToGroup` | Path 6 — can't add self to admin group |
| `iam:CreatePolicyVersion` | Path 2 — can't create permissive policy version |
| `iam:SetDefaultPolicyVersion` | Path 14 — can't switch to old permissive version |
| `iam:UpdateAssumeRolePolicy` | Path 10 — can't modify role trust policies |
| `organizations:*` | Prevents removing account from org, detaching SCPs |
| `account:*` | Prevents account-level setting changes |

Explicit `Deny` always overrides `Allow` in AWS. Even if an identity policy grants these, the boundary's explicit deny wins.

---

### `DenyDestructiveActions`

```json
"Action": [
    "s3:DeleteBucket", "s3:PutBucketPolicy", "s3:PutBucketAcl",
    "ec2:DeleteVpc", "ec2:DeleteSubnet", ...,
    "cloudtrail:StopLogging", "cloudtrail:DeleteTrail",
    "config:DeleteConfigRule", "config:StopConfigurationRecorder",
    "guardduty:DeleteDetector", "guardduty:DisassociateFromMasterAccount"
]
```

Prevents developers from accidentally or intentionally destroying infrastructure or disabling security controls.

The CloudTrail, Config, and GuardDuty denials are especially important — these are the logging and detection services. An insider threat or compromised developer role cannot blind your detection pipeline.

---

## How Boundary + Identity Policy Work Together

```
Developer identity policy allows:
  s3:* on arn:aws:s3:::dev-bucket-*

Developer boundary allows:
  s3:GetObject, s3:PutObject, s3:ListBucket, s3:DeleteObject

Effective permissions:
  s3:GetObject, s3:PutObject, s3:ListBucket, s3:DeleteObject
  on arn:aws:s3:::dev-bucket-*

  (intersection of both — boundary scopes the actions,
   identity policy scopes the resources)
```

The boundary does not grant `s3:DeleteBucket` — so even if the identity policy said `s3:*`, DeleteBucket is not effective. The boundary does not scope resources, so the identity policy's resource restriction still applies.

---

## Attaching This Boundary

When creating a developer role via Terraform:

```hcl
resource "aws_iam_role" "developer" {
  name                 = "developer-role"
  assume_role_policy   = data.aws_iam_policy_document.assume.json
  permissions_boundary = aws_iam_policy.developer_boundary.arn
}
```

Via CLI:
```bash
aws iam create-role \
  --role-name developer-role \
  --assume-role-policy-document file://trust.json \
  --permissions-boundary arn:aws:iam::123456789:policy/DeveloperBoundary
```

---

## Framework Mapping

| Framework | Control | Rationale |
|-----------|---------|-----------|
| MITRE ATT&CK | T1548.005 — Temporary Elevated Cloud Access | Boundary prevents elevation above developer ceiling |
| MITRE ATT&CK | T1078.004 — Valid Accounts: Cloud Accounts | Compromised developer role stays contained |
| NIST CSF 2.0 | PR.AC-4 — Manage access permissions | Least privilege enforced at identity level |
| CIS Controls v8.1 | 5.4 — Restrict Administrator Privileges | Developers cannot reach admin-equivalent permissions |
| OWASP Top 10:2025 | A01 — Broken Access Control | Boundary closes IAM escalation paths structurally |
