# AWS Terraform Bootstrap

The bootstrap root module creates the foundation that later Terraform configurations depend on. Its first responsibility is protected remote-state storage. Deployment identity is added as a separate, reviewable block after state behavior is understood.

## Why this exists

Terraform state maps configuration to real AWS resources. Losing it can make recovery difficult; exposing it can reveal infrastructure metadata or sensitive values; allowing concurrent writes can corrupt it.

The target design therefore uses:

- an Amazon S3 bucket with public access blocked
- bucket versioning for recovery from accidental overwrites or deletion
- encryption at rest
- native S3 state locking through `use_lockfile = true`
- least-privilege access to the required state and lock objects
- deletion protection and a documented break-glass recovery procedure

Native S3 locking is preferred for this implementation. DynamoDB-based locking is deprecated by Terraform and is not part of this new baseline.

## The bootstrap problem

The state bucket cannot store the state used to create itself until the bucket exists. Bootstrap therefore happens in two controlled phases:

1. Initialize and apply this root module with the default local backend using short-lived administrator credentials in a non-production AWS account.
2. Add and initialize the S3 backend only after the bucket exists, then explicitly migrate the bootstrap state and verify the remote copy.

During the first phase, the local state is sensitive. Keep it on an encrypted workstation, never commit it, restrict access to it, and remove it only after remote migration and version recovery are verified.

## Planned files

```text
bootstrap/
|-- README.md
|-- versions.tf
|-- providers.tf
|-- variables.tf
|-- state.tf
|-- github_oidc.tf
|-- outputs.tf
`-- terraform.tfvars.example
```

We will add these in small reviewable blocks:

1. Terraform and AWS provider requirements
2. input variables and required tags
3. S3 state storage and recovery controls
4. narrowly scoped outputs
5. GitHub OIDC provider and deployment role
6. backend migration instructions

## Lifecycle boundary

Bootstrap resources outlive ordinary development workloads. Do not place VPCs, compute instances, application resources, monitoring workloads, or environment-specific resources here.

Before applying, answer and document:

- Which AWS account and Region own the state?
- Which human and CI identities can read or modify it?
- Which state object paths can each identity access?
- How are object versions restored?
- How is a stale lock investigated before force-unlocking?
- How is deletion prevented, approved, and recovered?
- Where is the initial local state protected during migration?

## Validation gates

Before the first apply:

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
terraform plan
```

Review the plan for wildcard IAM, public access, unencrypted storage, destructive replacement, and unexpected cost. A successful static scan is necessary but does not authorize deployment.

## Recovery principle

Never delete state or force-unlock it simply because Terraform reports a lock. First verify that no other operation is running, preserve the error and lock details, and identify the owning process. Recovery actions must be narrow, logged, and reviewed.
