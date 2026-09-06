# Infrastructure Lint Container

A reproducible Linux AMD64 tool environment for infrastructure linting and static analysis.

## Included tools

- Hadolint, Gitleaks, OPA, and TFLint as standalone binaries
- cfn-lint, ansible-lint, yamllint, and Checkov from pinned Python requirements
- Git, Bash, and `jq`

Exact versions and binary hashes are defined in [`Dockerfile`](Dockerfile) and [`requirements.txt`](requirements.txt). Re-verify every hash against the publisher when updating a tool; never generate or guess a release checksum.

## Build and use

```bash
docker build -t cloud-ops-lint containers/images/lint-container
docker run --rm -v "$PWD:/app" cloud-ops-lint yamllint /app
docker run --rm -v "$PWD:/app" cloud-ops-lint cfn-lint /app/infrastructure/cloudformation/*.yaml
docker run --rm -v "$PWD:/app" cloud-ops-lint opa check /app/security/policy-as-code/opa
docker run --rm -v "$PWD:/app" cloud-ops-lint gitleaks detect --source /app --redact
```

The runtime image uses a non-root UID and does not include the builder's download tooling. The container still executes against mounted repository content, so use read-only mounts where the selected tool does not need to write.

The image is built and signed by [the publishing workflow](../../../.github/workflows/container-build-sign.yml) after relevant changes reach `main` or the workflow is manually dispatched.
