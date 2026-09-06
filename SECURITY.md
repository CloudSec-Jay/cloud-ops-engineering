# Security Policy

## Supported Versions

This is a cloud operations engineering repository. All active work targets the `main` branch.

| Branch | Supported |
|--------|-----------|
| `main` | ✅ |
| All others | ❌ |

---

## Reporting a Vulnerability

If you discover a security vulnerability in any artifact in this repository — including Terraform modules, Ansible roles, container images, Wazuh detection rules, or CI/CD pipeline configuration — please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

### How to Report

Open a [GitHub Security Advisory](https://github.com/CloudSec-Jay/cloud-ops-engineering/security/advisories/new) — this keeps the disclosure private until a fix is in place.

Include:
- Which file or component is affected
- A description of the vulnerability and its potential impact
- Steps to reproduce or proof of concept (if applicable)
- Suggested remediation (if known)

### Response Commitment

| Action | Timeframe |
|--------|-----------|
| Acknowledgement | Within 48 hours |
| Initial assessment | Within 7 days |
| Remediation or documented decision | Within 30 days |

---

## Security Controls in This Repository

All artifacts are subject to the DevSecOps Pipeline before merging to `main`:

- **gitleaks** — no hardcoded secrets or credentials committed
- **checkov** — IaC security policy enforcement (1000+ rules)
- **trivy** — HIGH/CRITICAL CVE blocking on IaC filesystem
- **hadolint** — Dockerfile best practice enforcement
- **OPA** — Rego policy correctness validation

Container images published to `ghcr.io/cloudsec-jay/` are signed with keyless cosign and have SBOM attestations in the Sigstore transparency log. Verify with:

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/CloudSec-Jay/cloud-ops-engineering" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/cloudsec-jay/<image>:latest
```

---

## Scope

| In Scope | Out of Scope |
|----------|-------------|
| Terraform modules and templates | Third-party Ansible Galaxy roles |
| Container Dockerfiles and images | Lab environment credentials (never committed) |
| GitHub Actions workflow configuration | Wazuh vendor binaries |
| Wazuh detection rules and SCA policies | |
| Python scripts and active response code | |
