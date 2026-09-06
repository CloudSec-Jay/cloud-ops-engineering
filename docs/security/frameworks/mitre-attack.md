# MITRE ATT&CK Coverage Map

This map uses MITRE ATT&CK Enterprise as a vocabulary for adversary behavior relevant to cloud, Linux, containers, identity, and CI/CD. ATT&CK mappings describe intent; they do not prove detection coverage.

Authoritative reference: [MITRE ATT&CK Enterprise](https://attack.mitre.org/matrices/enterprise/).

| Technique | Repository evidence | Coverage |
|---|---|---|
| T1078.004 Valid Accounts: Cloud Accounts | `security/policies/aws/`, Wazuh AWS integration | IAM guardrails plus cloud authentication-event ingestion guidance. |
| T1195.002 Compromise Software Supply Chain: Software Dependencies and Development Tools | `security/supply-chain/`, container build workflow | Dependency updates, checksums, SBOMs, image signing, and attestations. |
| T1548.005 Abuse Elevation Control Mechanism: Temporary Elevated Cloud Access | `security/policies/aws/iam/` | Permission-boundary and privilege-escalation guidance. |
| T1562.001 Impair Defenses: Disable or Modify Tools | CloudTrail-disable SCP, CI policy scans | Preventive AWS guardrail and configuration scanning. |
| T1070 Indicator Removal | Wazuh file-integrity rules and evidence | Host file changes and audit evidence support investigation. |
| T1552 Unsecured Credentials | Gitleaks workflow and `.gitignore` | Secret scanning and local-secret exclusions reduce committed credentials. |
| T1110 Brute Force | Wazuh authentication rules and triage runbooks | Detection and analyst response guidance. |
| T1021 Remote Services | Cilium default-deny policy and host hardening | Limits unapproved network paths and hardens administrative access. |
| T1565 Data Manipulation | Wazuh FIM, checksums, and signed SBOM attestations | Detects file changes and verifies artifact integrity. |
| T1059 Command and Scripting Interpreter | Linux Wazuh rules and active-response runbooks | Detects selected script and executable-permission activity. |

## Known gaps

- Cross-account role-assumption correlation is not implemented.
- Container runtime behavior requires a runtime sensor such as Falco or equivalent.
- Alert records are not yet copied to append-only storage.
- Detection mappings require tests with representative events and expected rule IDs.
