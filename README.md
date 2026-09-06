# Cloud Operations Engineering

A practical portfolio of cloud infrastructure, Linux automation, container operations, Kubernetes networking, observability, incident response, and preventive guardrails.

## Portfolio map

| Area | What is demonstrated | Entry point |
|---|---|---|
| Containers | Compose services, hardened utility images, and Podman Quadlets | [`containers/`](containers/README.md) |
| Infrastructure | Ansible, CloudFormation, and a clean Terraform layout | [`infrastructure/`](infrastructure/README.md) |
| Operations | Monitoring, Wazuh detection engineering, incident response, and recovery procedures | [`operations/`](operations/README.md) |
| Platform | Kubernetes networking, Cilium, RBAC, and workload identity patterns | [`platform/`](platform/README.md) |
| Security controls | AWS guardrails, OPA policy-as-code, checksums, SBOMs, and image signing | [`security/`](security/README.md) |
| Architecture and evidence | Threat models, framework maps, and evidence templates | [`docs/`](docs/README.md) |

Repository-specific working rules for Codex are in [`AGENTS.md`](AGENTS.md).

## Current maturity

- **Working examples:** Ansible playbooks, CloudFormation templates, AWS policy documents, OPA rules, Wazuh configurations, Compose files, and container build contexts.
- **Requires environment testing:** Kubernetes/Cilium setup, Wazuh deployments, active response, host hardening, and infrastructure deployment.
- **Scaffold only:** Terraform directories contain conventions and ownership boundaries but no active `.tf` resources.

Nothing in this repository should be treated as production-approved solely because it passes syntax or static analysis. Review plans, credentials, network exposure, rollback, and recovery in the target environment.

## Automated checks

GitHub Actions currently provides:

- Ansible, CloudFormation, YAML, Dockerfile, and OPA validation
- Compose configuration checks
- Checkov infrastructure scanning
- Gitleaks secret scanning
- Trivy vulnerability scanning
- Container build, SBOM generation, and keyless signing for selected images

See [`.github/workflows/`](.github/workflows/) for the exact implementation and versions.

## In-scope roadmap

The strongest next additions for a cloud operations engineer are:

1. Implement the Terraform AWS development environment and remote-state bootstrap.
2. Add AWS Organizations, IAM Identity Center, account-vending, and centralized logging patterns.
3. Add backup/restore and disaster-recovery runbooks with tested recovery objectives.
4. Add service-level indicators, alert thresholds, dashboards, and capacity checks.
5. Add patching, vulnerability remediation, and configuration-drift workflows.
6. Add cost allocation tags, budgets, anomaly detection, and lifecycle policies.
7. Add deployment promotion, rollback, and environment approval workflows.
8. Capture redacted evidence from successful tests without committing secrets or customer data.

AI/ML security labs, application-security training, pentesting labs, threat-hunting notebooks, forensics exercises, and archived websites are intentionally excluded.

## Safety

Copy example environment, variable, inventory, and secret files before adding local values. Never commit credentials, private keys, Terraform state, populated inventories, generated certificates, or unredacted operational evidence.

Use non-production accounts and hosts first. Review every destructive script and infrastructure plan before execution.

## Licensing

Original portfolio material is all rights reserved. Included or adapted third-party material remains under its original open-source license. See [`LICENSE`](LICENSE) and [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the applicable boundaries and notices.
