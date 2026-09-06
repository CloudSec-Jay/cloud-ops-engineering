# SCP Deployment Guide

How to create and attach Service Control Policies in AWS Organizations via Console and CLI.

---

## Prerequisites

- AWS Organizations must be enabled with **All Features** (not Consolidated Billing only)
- SCPs must be enabled as a policy type — they are off by default
- You must be operating from the **management account** — SCPs can only be managed from there
- IAM permissions required: `organizations:CreatePolicy`, `organizations:AttachPolicy`, `organizations:EnablePolicyType`

---

## Enable SCPs (one-time setup)

**Console:**
AWS Organizations → Policies → Service Control Policies → Enable

**CLI:**
```bash
# Get the root ID first
aws organizations list-roots

# Enable SCP policy type on the root
aws organizations enable-policy-type \
  --root-id r-xxxx \
  --policy-type SERVICE_CONTROL_POLICY
```

---

## The Hierarchy

```
Management Account
└── Root                     ← attach here to affect entire org
    ├── OU: Production
    │   ├── Account A        ← or attach here for one OU
    │   └── Account B
    └── OU: Dev
        └── Account C        ← or attach here for one account
```

SCPs are inherited downward. A policy attached at the root applies to every OU and account beneath it. A policy attached to an OU applies to all accounts in that OU only.

---

## Deploy via Console

1. AWS Organizations → Policies → Service Control Policies → **Create policy**
2. Name the policy (e.g. `DenyCloudTrailDisable`)
3. Paste the JSON content
4. Create policy
5. Navigate to the target — Root, OU, or specific account
6. Select the **Policies** tab → **Attach** → select your policy

---

## Deploy via CLI

```bash
# Step 1 — Create the policy
aws organizations create-policy \
  --name "DenyCloudTrailDisable" \
  --description "Blocks StopLogging, DeleteTrail, UpdateTrail org-wide" \
  --type SERVICE_CONTROL_POLICY \
  --content file://deny_cloudtrail_disable.json

# Step 2 — Get the policy ID from the output
# "PolicyId": "p-xxxxxxxxxxxx"

# Step 3 — Get the target ID (root, OU, or account)
aws organizations list-roots                        # root ID: r-xxxx
aws organizations list-organizational-units-for-parent --parent-id r-xxxx  # OU IDs
aws organizations list-accounts                     # account IDs: 12-digit numbers

# Step 4 — Attach the policy to the target
aws organizations attach-policy \
  --policy-id p-xxxx \
  --target-id r-xxxx
```

---

## How AWS Evaluates SCPs

SCPs work by defining the **maximum permissions** available in a member account. They do not grant permissions — they restrict what IAM policies inside the account can allow.

```
Request allowed only if:
  SCP allows the action
  AND IAM policy allows the action
```

AWS Organizations ships with a default SCP called `FullAWSAccess` attached to the root — it allows everything. Your deny SCPs layer on top of it. Do not remove `FullAWSAccess` unless you have a full allow-list SCP ready to replace it, or everything in every account breaks.

---

## Key Limitations

| Limitation | Detail |
|------------|--------|
| Management account is exempt | SCPs never apply to the management account — it requires separate controls |
| Root user in member accounts | SCPs do apply to root in member accounts (see `deny_root_action.json`) |
| No resource-level scoping | `Resource` must be `*` in SCPs — resource-level restrictions belong in IAM policies |
| No data plane actions | SCPs control the AWS API (control plane) only — they cannot restrict what happens inside an EC2 instance or what a Lambda function does at runtime |
| 5 SCPs per target | AWS enforces a default limit of 5 SCPs per root/OU/account — consolidate where needed |

---

## Testing Before Rollout

**Always test in a dev OU or isolated account before attaching to the org root or production OUs.**

```bash
# Simulate what a policy would do (dry run — does not attach)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/Developer \
  --action-names cloudtrail:StopLogging \
  --resource-arns "*"
```

Check the output for `DENY` — if the simulation returns allowed when you expect a deny, your condition logic needs review.

---

## Recommended Attachment Order

| Priority | SCP | Attach to |
|----------|-----|-----------|
| 1 | `deny_root_action` | Org root |
| 2 | `require_imdsv2` | Org root |
| 3 | `deny_cloudtrail_disable` | Org root |
| 4 | `deny_leave_organization` | Org root |
| 5 | `deny_public_s3` | Org root |
| 6 | `deny_non_approved_regions` | Production OU (not dev — breaks region flexibility) |
| 7 | `deny_iam_user_creation` | Org root (after IdP is confirmed working) |

`deny_non_approved_regions` and `deny_iam_user_creation` are called out specifically — applying them to the org root before validating your IdP and region setup will lock you out of legitimate workflows.
