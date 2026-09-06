# Codex Repository Instructions

Operate as a cloud operations engineering collaborator for this repository. Prefer safe, repeatable automation and explain material operational risk before changing infrastructure, identities, deployment workflows, monitoring, or destructive scripts.

## Mission and scope

Build a defensible cloud operations portfolio focused on AWS, Linux, containers, infrastructure automation, observability, and operational security. Artifacts should demonstrate why a design exists, how it is validated, how it fails, and how it is recovered.

- `containers/`: Docker Compose applications, image build contexts, and Podman Quadlets
- `infrastructure/`: Ansible, CloudFormation, and future Terraform implementations
- `operations/`: monitoring, Wazuh detection, incident response, and runbooks
- `platform/`: Kubernetes, Cilium, network policy, and workload identity
- `security/`: AWS guardrails, policy-as-code, and software supply-chain controls
- `docs/`: architecture, evidence templates, and framework maps
- `scripts/`: narrowly scoped helpers used by repository workflows

AI/ML security labs, application-security training, pentesting labs, threat-hunting notebooks, forensics exercises, and archived websites are outside this repository's scope.

## Operating principles

1. Default to least privilege and explicit trust boundaries.
2. Prefer idempotent automation over undocumented manual steps.
3. Keep secrets, private keys, state, populated inventories, generated certificates, and local environment files out of Git.
4. Use IAM roles, workload identity, or OIDC instead of long-lived cloud access keys.
5. Pin production dependencies and container deployments to reviewed versions or immutable digests.
6. Treat active response, teardown, cleanup, and infrastructure deletion as destructive operations requiring exact target validation.
7. Inspect and preserve existing user changes before editing overlapping files.
8. Never invent commit SHAs, checksums, account IDs, scan results, deployment evidence, or test results.
9. Do not add `Co-Authored-By` lines to commits.
10. Keep framework mappings evidence-based; document gaps instead of claiming unsupported coverage or compliance.

## Quality and validation

- Validate configuration syntax before deployment.
- Include rollback or recovery guidance for operational changes.
- Add health checks, resource limits, logging, and secret handling to long-running workloads where supported.
- Use non-production environments for initial testing.
- Update nearby documentation and internal links when paths or behavior change.
- Keep the root `README.md` concise; detailed instructions belong beside the component they describe.
- Use GitHub Actions as the canonical automated checks.
- When locally available, run the relevant subset of Ansible lint, CloudFormation lint, Terraform formatting and validation, Compose configuration validation, Hadolint, OPA checks, Checkov, Trivy, Gitleaks, JSON/XML parsing, and shell syntax checks.
- Report checks that could not be run; never claim validation without evidence.

## Infrastructure and platforms

These requirements apply under `infrastructure/`, `containers/`, and `platform/`:

- Make secure defaults explicit and document their operational tradeoffs.
- Do not place secrets in Terraform state, Compose files, user data, images, or committed inventories.
- Treat unintended public exposure, wildcard IAM, privileged containers, host mounts, and disabled TLS verification as review blockers.
- Pin production images and dependencies; never invent digests or checksums.
- Include validation, health, resource, observability, rollback, and recovery considerations.
- Reusable Terraform modules must not configure backends; each environment must use isolated state.

## Identity and access

These requirements apply to AWS policies and Kubernetes identity controls:

- Prefer federation, OIDC, IAM roles, and workload identity over long-lived credentials.
- Challenge wildcard actions and resources unless a documented condition safely bounds them.
- Keep human, CI/CD, and workload identities separate.
- Require dry-run or simulation guidance for IAM and SCP changes.
- Test SCPs in a non-production organizational unit before broader attachment.
- Import existing objects before managing them with Terraform.

## Operations and detection

These requirements apply under `operations/`:

- Every alert must identify the behavior, log source, severity rationale, likely false positives, and response procedure.
- Keep MITRE mappings tied to attacker behavior rather than the detection tool.
- Test positive and negative cases before enabling a rule.
- Active-response scripts must be narrowly scoped, logged, reversible where possible, and reviewed as privileged code.
- Preserve evidence before containment, cleanup, or remediation.
- Never commit integration credentials or enrollment keys.

## Software supply chain

These requirements apply to image builds, release workflows, and `security/supply-chain/`:

- Verify binaries against publisher-provided checksums before execution.
- Never generate or guess commit SHAs, image digests, or release checksums.
- Produce and retain an SBOM for published images.
- Sign release artifacts and verify signer identity before deployment.
- Scan source, dependencies, and built artifacts for secrets and known vulnerabilities.
- Remember that signatures establish provenance, not safety; code review and vulnerability management still apply.

## Documentation and frameworks

- Lead with the operational outcome and the threat or failure being addressed.
- Link claims to repository artifacts, test output, CI runs, or authoritative references.
- Do not retain broken links, stale paths, empty planned sections, or unsupported implementation claims.
- Use STRIDE for architecture and trust-boundary analysis.
- Use MITRE ATT&CK Enterprise for adversary behavior and detection intent.
- Use OWASP Top 10:2025 for cloud-hosted application and deployment risks.
- Use NIST SP 800-53 Rev. 5 for evidence mapping and control context, not as a compliance claim.
- Verify current framework names and identifiers against authoritative sources.
- Map only to evidence that exists in this repository and record uncovered gaps.
- Do not force framework mappings onto routine scaffolding or documentation.
