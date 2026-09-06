# OWASP Top 10:2025 Operations Map

The OWASP Top 10 is primarily an application-security awareness framework. This map includes only categories with meaningful cloud-operations evidence in this repository.

Authoritative reference: [OWASP Top 10:2025](https://owasp.org/Top10/).

| Category | Repository evidence | Operational contribution |
|---|---|---|
| A01 Broken Access Control | AWS IAM boundaries and SCPs; Kubernetes RBAC guidance | Limits administrative and workload permissions. |
| A02 Security Misconfiguration | Checkov, Ansible lint, CloudFormation lint, Hadolint, and OPA | Detects configuration errors before deployment. |
| A03 Software Supply Chain Failures | Dependabot, Trivy, checksums, SBOMs, and signed containers | Tracks dependencies and verifies build artifacts. |
| A04 Cryptographic Failures | Wazuh TLS configuration and encrypted AWS resource templates | Provides examples for protected transport and storage. |
| A05 Injection | Wazuh web-attack rules | Supplies detection examples; application-side prevention remains outside this repo. |
| A06 Insecure Design | STRIDE documents and default-deny network design | Records trust boundaries, controls, and accepted gaps. |
| A07 Authentication Failures | IAM guardrails, Kubernetes service accounts, and Wazuh authentication detection | Reduces shared identities and detects selected authentication attacks. |
| A08 Software or Data Integrity Failures | Cosign, SBOM attestations, checksums, and Wazuh FIM | Verifies artifacts and detects unexpected file changes. |
| A09 Security Logging and Alerting Failures | Wazuh rules, integrations, dashboards, and response runbooks | Connects collected events to alerts and analyst action. |
| A10 Mishandling of Exceptional Conditions | Container health checks and failure-aware automation are incomplete | Gap: add negative-path tests, explicit failure behavior, and recovery runbooks. |

## Boundary

This repository can provide platform controls, detection, and deployment safeguards, but application teams remain responsible for authorization logic, input validation, output encoding, safe error handling, and business-logic testing.
