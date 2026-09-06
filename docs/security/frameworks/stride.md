# STRIDE Threat Modeling

STRIDE is a component-level method for identifying six categories of threats and recording appropriate controls and gaps.

| Threat | Question | Typical cloud-operations controls |
|---|---|---|
| Spoofing | Can an actor impersonate an approved identity? | MFA, workload identity, short-lived credentials, and mutual authentication |
| Tampering | Can code, configuration, or data be modified without detection? | Signed artifacts, checksums, protected branches, TLS, and file-integrity monitoring |
| Repudiation | Can an actor deny an action because evidence is missing? | CloudTrail, workload audit logs, immutable retention, and synchronized time |
| Information Disclosure | Can an unauthorized actor read sensitive information? | Encryption, least privilege, secret stores, and log redaction |
| Denial of Service | Can resource exhaustion or dependency failure make the service unavailable? | Limits, quotas, health checks, scaling, backups, and tested recovery |
| Elevation of Privilege | Can an identity gain permissions beyond its intended role? | SCPs, permission boundaries, Kubernetes RBAC, OPA, and reviewed role assumption |

## Repository examples

| Component | Primary concerns | Evidence |
|---|---|---|
| AWS identity | Spoofing, information disclosure, elevation of privilege | `security/policies/aws/` |
| Containers | Tampering, disclosure, denial of service, elevation of privilege | `containers/`, signing workflow, Trivy, and Hadolint |
| CI/CD | Spoofing, tampering, repudiation, disclosure | Pinned actions, scoped permissions, Gitleaks, and review controls |
| Kubernetes networking | Spoofing, disclosure, denial of service | Dedicated service accounts, RBAC, and Cilium default deny |
| Wazuh | Tampering, repudiation, denial of service | FIM, alert records, tuning evidence, and response runbooks |

## Review process

1. Draw components, data stores, actors, and trust boundaries.
2. Identify data and control flow across each boundary.
3. Apply all six STRIDE questions to every crossing.
4. Link each proposed control to a repository artifact or deployed service.
5. Record unmitigated risks, owners, and review dates.
6. Revisit the model after architecture, identity, or deployment changes.

See the applied [infrastructure threat model](../infrastructure-threat-model.md).
