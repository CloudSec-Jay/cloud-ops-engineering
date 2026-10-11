# 01 — Infrastructure as Code with Drift Detection

## Outcome

Terraform builds a real AWS dev environment. Every day, a GitHub Actions job compares what's running against `main`. When someone changes infrastructure by hand, an issue opens that lists what drifted.

## What it proves

- You treat infrastructure as code and can recover from manual changes.
- You use short-lived CI credentials through OIDC instead of stored access keys.
- You have a triage process for drift: a drift report doesn't automatically mean "revert."

## Where it lives

- Root module: `infrastructure/terraform/aws/environments/dev/`
- Workflow: `.github/workflows/terraform-drift.yml`
- State: the bucket from `infrastructure/terraform/aws/bootstrap/`

## Requirements

### Fix first: bootstrap is broken

- [ ] `terraform validate` in `aws/bootstrap` fails with a **dependency cycle**. `data.aws_iam_policy_document.terraform_state_kms` sets `resources = [aws_kms_key.terraform_state.arn]`, but that same document is the key's own policy. In a key policy, `"*"` already means "this key."
- [ ] While you're in there, review the `s3.amazonaws.com` service-principal statement. For SSE-KMS, S3 uses the caller's KMS permissions, so the statement probably isn't needed.

### Dev root module

- [ ] Terraform and provider constraints matching bootstrap (`>= 1.14.0, < 2.0.0`, `hashicorp/aws ~> 6.0`)
- [ ] Partial `backend "s3" {}` with an uncommitted `backend.hcl` plus a committed `backend.hcl.example`. Add `backend.hcl` to `.gitignore`. Use S3 native locking (`use_lockfile = true`).
- [ ] `default_tags` for Environment, ManagedBy, Repository, and RootModule, so drift and cost trace back to code
- [ ] Start small: a VPC, a `aws_default_security_group` with no rules, and VPC flow logs to CloudWatch (log group retention ≥ 365 days, IAM role scoped to that log group only). Add subnets and compute after the first clean baseline.
- [ ] Variables with `validation` blocks (approved Regions, valid CIDR)
- [ ] Commit `.terraform.lock.hcl`
- [ ] README covering deploy, teardown (including what data is lost), and the drift triage runbook

### Drift workflow

- [ ] **validate job** on push and PR to `infrastructure/terraform/**`: `fmt -check -recursive`, `init -backend=false -lockfile=readonly`, `validate`. No credentials.
- [ ] **drift job** on `schedule` and `workflow_dispatch` only:
  - assume a **read-only** role through `aws-actions/configure-aws-credentials` (OIDC, `id-token: write`)
  - `terraform plan -detailed-exitcode -lock=false`. Exit code 0 means clean, 1 means error (fail the job), 2 means drift.
  - on drift, open one issue labelled `drift`, or comment on the existing open one
  - put **only resource addresses and actions** in the issue (`terraform show -json` piped through `jq`), never attribute values
- [ ] Skip the drift job until repository variables `AWS_PLAN_ROLE_ARN` and `TF_STATE_BUCKET` are set, so CI stays green before AWS is wired up
- [ ] Run it in a GitHub environment (for example `dev-readonly`) so the role trust policy can pin `sub` to `repo:CloudSec-Jay/cloud-ops-engineering:environment:dev-readonly`
- [ ] Pin actions to commit SHAs like the existing workflows. Resolved SHAs:
  - `hashicorp/setup-terraform` v4.0.1 → `dfe3c3f87815947d99a8997f908cb6525fc44e9e`
  - `aws-actions/configure-aws-credentials` v6.3.0 → `e1253824e5c10ff9df46874f81ed3ec929e19cfd`
  - Terraform CLI 1.16.3

### Plan role (create in bootstrap or by hand, then import)

- [ ] Trust: GitHub OIDC provider, `aud = sts.amazonaws.com`, `sub` pinned as above
- [ ] Read the state object (`s3:GetObject`, `s3:ListBucket` on the prefix, plus `kms:Decrypt` for the CMK)
- [ ] Describe, list, and get only on resource types in the module. No write actions.
- [ ] Run IAM Access Analyzer policy validation before attaching

## Done when (evidence)

- [ ] Green validate run on a PR
- [ ] Applied dev environment and a **clean** scheduled drift run (exit code 0)
- [ ] **The drift demo works:** add a rule to the default security group in the console, run the workflow, and the issue opens with the resource address. Revert or codify the change, and the next run is clean.
- [ ] Screenshot or link of the issue, plus the CloudTrail event that identified who made the change
- [ ] `terraform destroy` run and recorded

## Drift triage runbook (write this up in the README)

1. Don't apply immediately. The drift might be an emergency fix.
2. Use CloudTrail to find who made the change, when, and why.
3. Either codify it (PR) or revert it (reviewed plan and apply from `main`).
4. Close the issue with a link to the PR or apply run.
5. For false positives (provider default changes, AWS-managed tags), fix the code with `ignore_changes` and a comment explaining why. Never mute the workflow.

## Out of scope

Production, multi-account setup, and reusable modules until a second environment needs them.
