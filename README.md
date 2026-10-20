# Cloud Operations Engineering

A practical portfolio of cloud infrastructure, Linux automation, container operations, observability, incident response, and preventive guardrails.

This repository is the hub of one system. Each field project lives in its own repository, has its own GitHub Pages site, and links back here; the hub keeps the shared operations, infrastructure, and security foundations.

The [portfolio website](docs/site/index.html) presents the projects and their validation boundaries. See [site maintenance and publishing](docs/site-maintenance.md).

## System map

| # | Project | What it owns | Repository | Site |
|---|---|---|---|---|
| Hub | Cloud Operations Engineering | Shared infrastructure, containers, operations, and security foundations | this repository | [site](https://cloudsec-jay.github.io/cloud-ops-engineering/) |
| 01 | Hardened AWS Workload | Dragonwilds dedicated server run like production: Packer/Ansible AMIs, CloudFormation, retained EBS, Falco, CloudWatch | [`dragonwilds-aws`](https://github.com/CloudSec-Jay/dragonwilds-aws) | [site](https://cloudsec-jay.github.io/dragonwilds-aws/) |
| 02 | Kubernetes SecOps | kubeadm VM cluster, Cilium/Hubble, Wazuh, and detection content | [`k8s-secops-platform`](https://github.com/CloudSec-Jay/k8s-secops-platform) | [site](https://cloudsec-jay.github.io/k8s-secops-platform/) |
| 03 | AI/ML Security | Agent, MCP, LLM, and MLOps attack surface and controls | [`ai-ml-security`](https://github.com/CloudSec-Jay/ai-ml-security) | [site](https://cloudsec-jay.github.io/ai-ml-security/) |
| 04 | Compliance Guardrails & Integrity | AWS guardrails, OPA admission, evidence mapping, SBOMs, and signing | [`compliance-guardrails-integrity`](https://github.com/CloudSec-Jay/compliance-guardrails-integrity) | [site](https://cloudsec-jay.github.io/compliance-guardrails-integrity/) |
| 05 | Cloud Resilience & Recovery | AWS Backup restore testing, RTO/RPO scorecards, recovery evidence | [`cloud-resilience-recovery`](https://github.com/CloudSec-Jay/cloud-resilience-recovery) | [site](https://cloudsec-jay.github.io/cloud-resilience-recovery/) |
| Special practice | Red Team Lab Engineering | Authorized adversary emulation with detection handoff to SecOps | [`red-team-lab-engineering`](https://github.com/CloudSec-Jay/red-team-lab-engineering) | [site](https://cloudsec-jay.github.io/red-team-lab-engineering/) |

Workload-specific implementation stays in the owning repository; reusable methods and shared foundations are linked rather than duplicated.

## Hub contents

| Area | What is demonstrated | Entry point |
|---|---|---|
| Containers | Compose services, hardened utility images, and Podman Quadlets | [`containers/`](containers/README.md) |
| Infrastructure | Ansible, CloudFormation, and a clean Terraform layout | [`infrastructure/`](infrastructure/README.md) |
| Operations | Incident response, recovery procedures, and capacity analytics | [`operations/`](operations/README.md) |
| Platform | Pointers to the dedicated Kubernetes SecOps project | [`platform/`](platform/README.md) |
| Security controls | AWS guardrails, OPA policy-as-code, checksums, SBOMs, and image signing | [`security/`](security/README.md) |
| Architecture and evidence | Threat models, framework maps, and evidence templates | [`docs/`](docs/README.md) |

Repository-specific working rules for Codex are in [`AGENTS.md`](AGENTS.md).

## Current maturity

- **Working examples:** Ansible playbooks, CloudFormation templates, AWS policy documents, OPA rules, Compose files, SQL migrations, and container build contexts.
- **In progress:** The AWS Terraform bootstrap contains active provider, variable, S3, and KMS configuration but has no recorded deployment evidence. EC2 capacity analytics contains a local MySQL/Grafana stack and two schema migrations; collection, dashboards, and AWS integration remain incomplete.
- **Requires environment testing:** Terraform plans, host hardening, and infrastructure deployment. Kubernetes/Wazuh testing is tracked in the dedicated SecOps platform repository.
- **Scaffold only:** Terraform development, production, reusable-module, and GitHub roots remain documentation-only.

Nothing in this repository should be treated as production-approved solely because it passes syntax or static analysis. Review plans, credentials, network exposure, rollback, and recovery in the target environment.

## Automated checks

GitHub Actions currently provides:

- Ansible, CloudFormation, YAML, Dockerfile, and OPA validation
- Compose configuration checks for stacks under `containers/compose/`; the capacity-analytics stack is not yet included
- Checkov infrastructure scanning
- Gitleaks secret scanning
- Trivy vulnerability scanning
- Container build, SBOM generation, and keyless signing for selected images

See [`.github/workflows/`](.github/workflows/) for the exact implementation and versions.

## In-scope roadmap

The strongest next additions for a cloud operations engineer are:

1. Implement the Terraform AWS development environment and remote-state bootstrap.
2. Add AWS Organizations, IAM Identity Center, account-vending, and centralized logging patterns.
3. Integrate workload-specific recovery hooks with the standalone [Cloud Resilience & Recovery](https://github.com/CloudSec-Jay/cloud-resilience-recovery) scaffold, then capture measured restoration evidence.
4. Add service-level indicators, alert thresholds, dashboards, and capacity checks.
5. Add patching, vulnerability remediation, and configuration-drift workflows.
6. Add cost allocation tags, budgets, anomaly detection, and lifecycle policies.
7. Add deployment promotion, rollback, and environment approval workflows.
8. Capture redacted evidence from successful tests without committing secrets or customer data.

This roadmap covers the hub. AI/ML security, adversary emulation, compliance, and recovery work are tracked in their own project repositories listed in the [system map](#system-map). Threat-hunting notebooks, forensics exercises, and archived websites remain out of scope.

## Safety

Copy example environment, variable, inventory, and secret files before adding local values. Never commit credentials, private keys, Terraform state, populated inventories, generated certificates, or unredacted operational evidence.

Use non-production accounts and hosts first. Review every destructive script and infrastructure plan before execution.

## Licensing

Original portfolio material is all rights reserved. Included or adapted third-party material remains under its original open-source license. See [`LICENSE`](LICENSE) and [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the applicable boundaries and notices.
