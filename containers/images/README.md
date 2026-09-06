# Container Images

Two in-scope utility images are published by the container build workflow:

| Image | Purpose | Documentation |
|---|---|---|
| `lint-container` | Reproducible infrastructure linting and static analysis | [`lint-container/`](lint-container/README.md) |
| `toolbox` | AWS, Terraform, Packer, Ansible, signing, and scanning tools | [`toolbox/`](toolbox/README.md) |

Both build contexts use non-root runtime users and multi-stage builds. Downloaded standalone binaries are checked against hashes stored in their Dockerfiles. Those hashes must be independently re-verified against publisher releases whenever a version changes.

The GitHub Actions publishing workflow builds Linux AMD64 images, pushes commit and `latest` tags to GHCR, generates SPDX SBOMs, and signs image digests with GitHub OIDC.
