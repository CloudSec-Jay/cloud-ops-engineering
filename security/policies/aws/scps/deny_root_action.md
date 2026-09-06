# SCP: Deny Root Account Actions

**File:** `deny_root_action.json`
**Scope:** AWS Organization — applies to all member accounts
**Type:** Service Control Policy (SCP)

---

## What This Does

Blocks the AWS root account from performing any API action in any account across the organization. Root credentials that are compromised or misused cannot execute a single AWS API call when this SCP is attached at the org root or OU level.

---

## Line-by-Line Breakdown

```json
"Version": "2012-10-17"
```
The AWS policy language version. This value never changes — it is a required field that tells AWS which policy grammar to use.

---

```json
"Statement": [ ]
```
An array. Every policy can contain multiple statements (multiple rules). Using `[]` instead of `{}` is required — AWS rejects object syntax here.

---

```json
"Sid": "DenyRootAllActions"
```
Statement ID — a human-readable label. No functional effect. Used for auditing, CloudTrail filtering, and identifying the rule in large multi-statement policies.

---

```json
"Effect": "Deny"
```
Explicit deny. In AWS, an explicit Deny always wins over any Allow — even if an identity policy grants the action, this Deny overrides it. SCPs work by restricting the maximum permissions available in an account, so a Deny here cannot be overridden by anything inside the account.

---

```json
"Action": "*"
```
Every API action across every AWS service. Combined with the Condition below, this means root cannot call any AWS API — not `ec2:DescribeInstances`, not `s3:GetObject`, nothing. The wildcard is intentional and safe here because it is fully scoped by the Condition block.

---

```json
"Resource": "*"
```
Every resource in AWS. Required field — a Statement without `Resource` is invalid and AWS will reject the policy.

---

```json
"Condition": {
    "StringLike": {
        "aws:PrincipalArn": "arn:aws:iam::*:root"
    }
}
```

This is the scope control — without it, `Deny *` on `Resource: *` would lock out every IAM user and role in the account, not just root.

**`aws:PrincipalArn`** — a global condition key that evaluates to the ARN of the caller making the API request. For root, this is always `arn:aws:iam::<account-id>:root`.

**`StringLike`** — used instead of `StringEquals` because the ARN contains a wildcard (`*`) in the account ID position. `StringLike` supports `*` as a wildcard; `StringEquals` does exact string matching only.

**`arn:aws:iam::*:root`** — matches root in any account ID. The double colon `::` is intentional — root ARNs have no region component (IAM is global). The `*` in the account ID position matches all 12-digit account IDs across the organization.

---

## Why Root Cannot Be Fully Restricted

AWS exempts four root-only tasks from SCP enforcement. These are account lifecycle operations that AWS requires root for and cannot delegate:

1. Close the AWS account
2. Change the root account email address or password
3. Enable or disable MFA on the root account
4. Restore IAM access when all admin IAM users are locked out

Everything else — every operational task — should be performed by an IAM role. This SCP enforces that.

---

## Real-World Breaches

### T1078.004 — Valid Accounts: Cloud Accounts

**Story 1 — Individual root takeover (2023)**
In April 2023, an AWS user received an email about unusual login activity at 5:14AM. Two minutes later the attacker changed the root account email address, locking the real owner out completely. With root access and no MFA, the attacker spun up EC2 instances, load balancers, and VPCs in a foreign region and ran up a significant bill before AWS intervened. Root had no SCP restricting API calls.
- Source: [AWS re:Post — Root account hacked and email updated](https://repost.aws/questions/QUNC4jgG36Q12-pqtiPZreXw/root-account-hacked-and-email-updated)

**Story 2 — Credential exposure via .env file**
A developer committed a `.env` file containing AWS root credentials to a public GitHub repository. An automated scanner (common in credential harvesting operations) picked up the keys within minutes. The attacker used root credentials to create IAM users with AdministratorAccess, establishing persistence before the developer noticed and rotated the keys. Because root has no permission boundary, the attacker had unrestricted access to every service.
- Source: [GitHub — aws-customer-security-incidents](https://github.com/ramimac/aws-customer-security-incidents)

**Story 3 — Phishing root credentials**
A spear-phishing campaign targeting AWS account owners spoofed an AWS billing alert email. The victim clicked through to a convincing fake AWS console login page and entered their root credentials. The attacker logged in, disabled CloudTrail logging, and began exfiltrating data from S3 before the victim realized. Without an SCP blocking root API calls, disabling CloudTrail took a single API call.
- Source: [Medium — My horror story discovering my AWS root account was hacked](https://medium.com/@kariarce2377/my-horror-story-discovering-that-my-aws-root-account-was-hacked-2cf3ce41bc47)

---

### T1098 — Account Manipulation

**Story 1 — Root used to create backdoor IAM admin**
After gaining root access through a leaked credential, an attacker created a new IAM user with AdministratorAccess and programmatic access keys. This established persistence — even if the root password was rotated, the backdoor IAM user remained active. Root is the only principal that cannot be restricted by SCPs, making it the ideal foothold for persistence.

**Story 2 — Root MFA disabled to maintain access**
An attacker with temporary root access disabled MFA on the root account before the legitimate owner could respond. This meant the attacker could re-authenticate as root at any time using only the password, even after the owner believed they had secured the account by changing the password.

**Story 3 — IAM policy manipulation via root**
In a documented insider threat case, a departing employee used root credentials they had retained to modify IAM policies on their last day — granting excessive permissions to a personal AWS account and revoking access for other admins. Root manipulation of IAM policies is undetectable by permission boundaries and unblockable by SCPs on individual IAM actions without this deny-all control.

---

## Defense-in-Depth Stack

| Control | What it prevents |
|---------|-----------------|
| MFA on root | Blocks login even with stolen password |
| This SCP | Blocks all API calls even if login succeeds |
| Break-glass process | Defines the only legitimate use of root |
| CloudTrail alerting | Detects root usage immediately |
| AWS Organizations SCPs | Enforces org-wide — member account admins cannot override |

---

## Framework Mapping

| Framework | Control | Rationale |
|-----------|---------|-----------|
| MITRE ATT&CK | T1078.004 — Valid Accounts: Cloud Accounts | Root credential abuse is the highest-impact cloud account takeover vector |
| MITRE ATT&CK | T1098 — Account Manipulation | Root is used to create backdoor IAM users and modify policies to maintain access |
| OWASP Top 10:2025 | A01:2025 — Broken Access Control | Root bypasses all access controls; this SCP closes that gap org-wide |
| STRIDE | Elevation of Privilege | Compromised root credentials grant unrestricted privilege — no boundary, no policy stops it without this SCP |
