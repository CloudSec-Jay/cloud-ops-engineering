# Terraform

This directory defines where future Terraform code belongs. It intentionally contains no active `.tf` resources yet.

## Layout

```text
terraform/
|-- aws/
|   |-- bootstrap/       one-time remote-state foundation
|   |-- environments/
|   |   |-- dev/         development root module
|   |   `-- prod/        production root module
|   `-- modules/         reusable AWS modules
`-- github/              GitHub administration root module
```

## Repository conventions

- Declare Terraform and provider version constraints in each root module.
- Commit dependency lock files.
- Keep reusable modules free of backend configuration.
- Isolate state, credentials, and deployment approval by environment.
- Use encrypted, versioned remote state with locking and tightly scoped access.
- Never commit state, saved plans, credentials, or populated variable files.
- Run formatting, validation, static analysis, and a reviewed plan before applying.
- Import existing resources before attempting to manage them.

Suggested validation after implementation:

```bash
terraform fmt -check -recursive infrastructure/terraform
terraform -chdir=infrastructure/terraform/PATH init -backend=false
terraform -chdir=infrastructure/terraform/PATH validate
```

Start with [`aws/bootstrap/`](aws/bootstrap/README.md), then implement [`aws/environments/dev/`](aws/environments/dev/README.md). Promote reviewed modules and patterns to production only after recovery and state-access procedures are tested.
