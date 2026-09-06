# Infrastructure

Infrastructure provisioning and host configuration are organized by tool and lifecycle.

## Components

- [`ansible/`](ansible/README.md): Linux hardening, package/service configuration, and system maintenance
- [`cloudformation/`](cloudformation/README.md): AWS network, security-group, serverless, and detection-pipeline examples
- [`terraform/`](terraform/README.md): an empty, documented structure for future AWS and GitHub resources

Container workloads live under [`containers/`](../containers/README.md); Kubernetes platform configuration lives under [`platform/`](../platform/README.md).

## Change workflow

1. Validate syntax and static-analysis findings.
2. Review the plan or change set and its IAM impact.
3. Test in a non-production environment.
4. Capture evidence and confirm monitoring.
5. Document rollback and recovery before production promotion.

Never commit credentials, populated inventories, generated certificates, plans, state, or populated variable files.
