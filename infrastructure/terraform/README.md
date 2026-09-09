# Terraform

This directory contains the infrastructure-as-code implementation for the AWS Operations Baseline. The first objective is not to create many AWS resources; it is to establish a safe, repeatable path from configuration to deployment, validation, recovery, and teardown.

## Learning path

Build the platform in this order:

1. **Bootstrap state:** create protected remote-state storage and document how state is recovered.
2. **Establish deployment identity:** use GitHub OIDC and an AWS IAM role instead of long-lived access keys.
3. **Deploy development:** build the first AWS environment with explicit networking, identity, compute, logging, patching, backup, and cost controls.
4. **Operate and recover:** validate health, test restoration, record evidence, and confirm teardown behavior.
5. **Extract modules:** move proven, reusable boundaries into modules only after a second environment needs them.
6. **Consider production:** keep production documentation-only until development deployment and recovery are demonstrated.

## Layout

```text
terraform/
|-- aws/
|   |-- bootstrap/       one-time state and deployment-identity foundation
|   |-- environments/
|   |   |-- dev/         first deployable AWS root module
|   |   `-- prod/        documentation only until promotion criteria are met
|   `-- modules/         reusable components extracted from proven designs
`-- github/              separate GitHub administration root module
```

## Root-module responsibilities

Each deployable root module owns its:

- Terraform and provider version constraints
- provider and backend configuration
- environment-specific variables, local values, and outputs
- state key and deployment identity
- validation, deployment, rollback, and recovery documentation

Reusable modules must not configure a backend, embed credentials, or assume an environment-specific state key.

## Repository safeguards

- Never commit credentials, `.tfstate`, saved plans, populated `.tfvars`, or generated backend files containing sensitive values.
- Commit `.terraform.lock.hcl` after `terraform init` so provider selection is reproducible.
- Use short-lived role credentials locally and GitHub OIDC in automation.
- Run `plan` before `apply`; review replacements, deletions, public exposure, IAM changes, and projected cost.
- Test in development first and make teardown targets explicit.
- Import existing AWS resources before attempting to manage them.

## Validation

Run these commands from the repository root when Terraform is installed:

```bash
terraform fmt -check -recursive infrastructure/terraform
terraform -chdir=infrastructure/terraform/aws/bootstrap init -backend=false
terraform -chdir=infrastructure/terraform/aws/bootstrap validate
```

GitHub Actions remains the canonical validation record. Local success does not prove that an AWS deployment is safe or recoverable.

Start with [`aws/bootstrap/`](aws/bootstrap/README.md). The development environment follows only after the state foundation has been reviewed and applied in a non-production AWS account.
