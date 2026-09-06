# STRIDE Threat Model — Cloud Security Infrastructure

**Scope:** CI/CD pipeline, AWS infrastructure, container supply chain, IAM controls, Wazuh detection stack, Fedora workstation (agent host).
**Methodology:** STRIDE per component. This model was migrated from the previous repository and must be revalidated as implementations change.
**Last Updated:** 2026-03-31

---

## 1. Architecture Decomposition

| Component | Asset | Trust Boundary | Entry Points |
|---|---|---|---|
| CI/CD Pipeline | GitHub Actions runner, workflow tokens, secrets | Internet → GitHub → AWS | Git push, PR, scheduled trigger |
| Container Supply Chain | Base images, binaries, signed artifacts (ghcr.io) | Build environment → registry → runtime | `docker pull`, CI matrix build |
| AWS Infrastructure | Terraform state (S3), IAM roles, VPC, S3 buckets | Developer workstation → AWS APIs | `terraform apply`, AWS Console, API calls |
| Identity & IAM | IAM roles, SCPs, permission boundaries, root account | AWS org boundary | Console login, API calls, assumed roles |
| Wazuh Detection Stack | Manager (Docker), agent (Fedora), alert data, rules | Agent host → manager container | TCP 1514 (agent), HTTPS 443 (dashboard), API 55000 |
| Fedora Workstation | OS config, credentials, monitored paths, audit log | Physical/network access | SSH, local session, package install |

---

## 2. STRIDE Analysis

### CI/CD Pipeline — `.github/workflows/security_pipeline.yml`

| Threat | Description | Control | Gap |
|---|---|---|---|
| **Spoofing** | Attacker submits PR from forked repo to trigger pipeline with elevated permissions | `pull_request` trigger — secrets not exposed to forks; `permissions: read-all` set | Third-party Actions not all pinned to commit SHA |
| **Tampering** | Malicious commit modifies workflow file to exfiltrate secrets or skip security gates | Branch protection + required reviews | No signed commits enforced |
| **Repudiation** | Attacker deletes workflow run logs to erase evidence of pipeline abuse | GitHub audit log (org-level) | Log retention not explicitly configured |
| **Info Disclosure** | Secrets leaked via `echo` in workflow steps or exposed in build artifacts | Gitleaks filesystem scan (`scan-secrets` job) blocks committed secrets | Runtime secret exposure (env vars in logs) not monitored |
| **Denial of Service** | Workflow triggered in loop to exhaust GitHub Actions minutes | — | No concurrency limits configured |
| **Elevation of Privilege** | Compromised workflow token used to write to repo or push to registry | `permissions: read-all` at workflow level; scoped per-job where write needed | `GITHUB_TOKEN` scope not minimized per job |

---

### Container Supply Chain — `containers/` · `security/supply-chain/`

| Threat | Description | Control | Gap |
|---|---|---|---|
| **Spoofing** | Attacker publishes malicious image to ghcr.io under similar name | Cosign keyless signing — every published image has Sigstore Rekor entry | Verification at pull time not enforced in all contexts |
| **Tampering** | Base image or binary replaced with compromised version between build and deploy | SHA256 digest pins on all base images; binary checksums verified at build time | Dependabot watches versions, not digest changes |
| **Repudiation** | No record of who built and signed a given image | Cosign attestation + Sigstore transparency log — immutable, publicly auditable | — |
| **Info Disclosure** | Secrets baked into image layers during build | Multi-stage builds — Stage 1 fetches, Stage 2 has no `curl` or credentials | `docker history` not audited post-build |
| **Denial of Service** | Registry unavailable blocks all deployments | — | No local mirror or fallback |
| **Elevation of Privilege** | Container runs as root, escapes to host | Non-root user (UID 10001) in all images; no `docker.sock` mount | Rootless Podman not enforced in all environments |

---

### AWS Infrastructure — `infrastructure/terraform/aws/`

| Threat | Description | Control | Gap |
|---|---|---|---|
| **Spoofing** | Attacker assumes a role via confused deputy or misconfigured trust policy | IAM role trust policies scoped to specific principals; no wildcard principals | Trust policy review not automated |
| **Tampering** | Manual console change drifts from Terraform state (SG opened to 0.0.0.0/0) | Checkov IaC scan blocks misconfigs before deploy; `terraform plan` detects drift | No automated drift detection on deployed resources |
| **Repudiation** | Attacker disables CloudTrail to erase API call history | SCP `deny_cloudtrail_disable` — blocks `StopLogging`, `DeleteTrail`, `UpdateTrail` org-wide | CloudTrail log integrity validation not yet configured |
| **Info Disclosure** | Terraform state file exposes secrets or resource ARNs | S3 backend with SSE-KMS; versioning enabled | No secrets should be in state — enforced by `no-secrets.rego` (planned) |
| **Denial of Service** | Resource exhaustion via runaway Terraform apply or API rate limiting | — | No Sentinel/OPA policy bounding resource creation |
| **Elevation of Privilege** | Developer uses `iam:PassRole` to attach admin policy to exploitable resource | `developer_boundary.json` closes 14 PrivEsc paths including PassRole chains | Boundary enforcement verified at design time, not continuously |

---

### Identity & IAM — `security/policies/aws/iam/`

| Threat | Description | Control | Gap |
|---|---|---|---|
| **Spoofing** | Attacker uses stolen long-term IAM user access key | SCP `deny_iam_user_creation` — no IAM users; federated identity only | Key rotation policy not enforced via SCP |
| **Tampering** | Attacker modifies SCP to remove a control | SCP changes require management account credentials; root actions blocked by `deny_root_action` SCP | SCP change alerting (CloudTrail rule) not yet deployed |
| **Repudiation** | Privilege escalation performed via rarely-audited API (`iam:CreatePolicyVersion`) | CloudTrail detection queries documented in `privilege-escalation/cloudtrail_detection_queries.md` | Wazuh CloudTrail integration not yet deployed — no live alerting |
| **Info Disclosure** | IAM role trust policy exposes `sts:AssumeRole` to external account | Trust policies scoped to explicit principals; no `*` in trust | No automated policy review in CI |
| **Denial of Service** | SCP misconfiguration locks out all accounts from a required service | SCPs tested manually; `deny_non_approved_regions` has global service exceptions | No SCP simulation testing in CI |
| **Elevation of Privilege** | Attacker chains `PassRole` + `lambda:InvokeFunction` to assume admin role | `developer_boundary.json` blocks 14 documented escalation paths | Boundary does not cover all AWS service roles |

---

### Wazuh Detection Stack — `operations/monitoring/wazuh/`

| Threat | Description | Control | Gap |
|---|---|---|---|
| **Spoofing** | Rogue agent connects to manager using stolen enrollment key | Agent enrollment via pre-shared key; manager should use a private address | Mutual TLS between agent and manager not configured |
| **Tampering** | Attacker modifies detection rules on manager to suppress alerts | Rules stored in repo — any change is tracked in git; manager in Docker with mounted config | No file integrity monitoring on the manager container itself |
| **Repudiation** | Alert deleted from OpenSearch index to erase evidence | — | OpenSearch index immutability not configured; no external log forwarding yet |
| **Info Disclosure** | Dashboard credentials exposed (`docker-compose.yml` defaults not rotated) | Credentials in compose file are lab defaults — not production | Secrets should be in Docker secrets or env file excluded from git |
| **Denial of Service** | inotify queue overflow causes FIM event loss during high-churn activity | Documented in `evidence/FIM_HARDENING_STORM.md`; tuning rules reduce noise | `max_queued_events` not permanently increased in sysctl |
| **Elevation of Privilege** | Wazuh active response script runs as root — compromised script = host root | Active response scripts in repo — reviewed before deploy | No allowlist validation on active response execution |

---

### Fedora Workstation — `operations/monitoring/wazuh/agent-configs/ossec.conf`

| Threat | Description | Control | Gap |
|---|---|---|---|
| **Spoofing** | Attacker SSHes in with a stolen administrator credential | Restrict allowed SSH users, disable root login, and limit authentication attempts | No hardware MFA on SSH (key-based only) |
| **Tampering** | Attacker modifies `/etc/sudoers`, PAM config, or SSH authorized_keys | FIM rules 100004 (sudoers), 100005 (authorized_keys), 100006 (PAM) — level 12 alerts | Rules fire on change detection, not prevention |
| **Repudiation** | Privilege escalation performed without audit record | auditd + Wazuh FIM whodata captures effective UID and process name for every monitored file change | auditd rules immutable flag requires reboot to change — verify survives reboot |
| **Info Disclosure** | Credentials or private keys readable by unprivileged process | `/root/.ssh/` monitored by FIM; CIS hardening sets restrictive permissions | No automated check that new files in `/root` aren't world-readable |
| **Denial of Service** | Disk filled by Wazuh log accumulation | Wazuh log rotation configured; journald compression enabled via CIS hardening | No alert on Wazuh disk usage threshold |
| **Elevation of Privilege** | `chmod +x` staging in `/tmp` followed by execution | FIM rules 100002/100003/100007 detect permission staging and script drops | Does not correlate file drop + chmod + execute as a single attack chain |

---

## 3. Residual Risk

| Risk | Component | Reason Not Fixed | Accepted? |
|---|---|---|---|
| No mTLS between Wazuh agent and manager | Wazuh | Lab environment; PKI setup deferred | Yes — lab only |
| Wazuh dashboard uses default compose credentials | Wazuh | Lab environment | Yes — not internet-exposed |
| CloudTrail integration not live | IAM / Detection | Wazuh integration backlog (Priority 2) | No — track in the operations backlog |
| SCP change alerting not deployed | IAM | Same — CloudTrail integration prerequisite | No — tracked |
| `max_queued_events` not persisted | Fedora | Requires sysctl.d entry | No — low effort, not yet done |
| No signed commits enforced | CI/CD | Developer friction on workstation | Yes — git history is sufficient for lab |

---

## 4. Gaps Not Addressed by Any Control

- **Agent-to-manager communication integrity** — no verification that rules/configs pushed from manager are unmodified
- **Active response blast radius** — no scope limit on what an active response script can do on the host
- **Alert pipeline integrity** — alerts can be deleted from OpenSearch; no append-only log store
- **Cross-account lateral movement correlation** — CloudTrail events not yet ingested; no rule for `sts:AssumeRole` chaining across accounts
