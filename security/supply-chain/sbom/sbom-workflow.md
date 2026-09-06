# SBOM Workflow

A Software Bill of Materials (SBOM) is a machine-readable inventory of the packages and libraries included in an artifact. It supports dependency review, license analysis, and vulnerability investigation; it does not prove that an artifact is safe.

## Automated workflow

The container publishing workflow at [`.github/workflows/container-build-sign.yml`](../../../.github/workflows/container-build-sign.yml) builds selected images, generates SPDX JSON with Anchore's SBOM action, and attaches the SBOM as a cosign attestation to the published image digest.

The current build matrix includes:

- `lint-container`
- `toolbox`

Workflow output and attestations exist only after a successful GitHub Actions run. Do not record them as completed evidence until the run and published digest have been verified.

## Verify an attestation

```bash
cosign verify-attestation \
  ghcr.io/cloudsec-jay/IMAGE@sha256:DIGEST \
  --type spdxjson \
  --certificate-identity-regexp "https://github.com/CloudSec-Jay/cloud-ops-engineering" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

Replace `IMAGE` and `DIGEST` with values from a verified workflow run. Tighten the certificate identity expression to the exact workflow identity before using it as a deployment gate.

## Generate and scan locally

```bash
syft IMAGE:TAG -o spdx-json > sbom.spdx.json
grype sbom:sbom.spdx.json --fail-on high
```

Generated SBOM files are evidence artifacts. Store them with the associated immutable image digest and retain them according to the release-evidence policy.
