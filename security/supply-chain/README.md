# Software Supply Chain

Controls in this area help establish artifact integrity and provenance from download through container publication.

## Components

- [`checksum-validator/`](checksum-validator/README.md): local file hashing and a Bash download-and-verify helper
- [`sbom/sbom-workflow.md`](sbom/sbom-workflow.md): SBOM generation, scanning, storage, and attestation guidance
- [`container-build-sign.yml`](../../.github/workflows/container-build-sign.yml): container build, GHCR publication, SPDX SBOM generation, and keyless cosign signing

## Required controls

- Pin production dependencies, workflow actions, and images to reviewed versions or immutable references.
- Obtain checksums from an authenticated publisher channel and review them independently.
- Scan source, dependencies, build output, and final images for secrets and known vulnerabilities.
- Associate every SBOM, signature, and scan result with the immutable artifact digest.
- Verify signer identity and issuer in deployment policy.
- Protect build logs and attestations from credential leakage.
- Define a response process for newly disclosed vulnerabilities and compromised dependencies.

A signature establishes provenance, not safety. An SBOM establishes inventory, not vulnerability status. Both controls require review, scanning, and remediation processes.
