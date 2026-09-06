# Linting & Security Tools Container
# CIS Docker 4.1 - Non-root user
# CIS Docker 4.3 - Pinned base image digest
# NIST 800-190 - Immutable infrastructure

# Stage 1 — download and verify binaries, curl stays here
FROM alpine:3.23.3@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659 AS builder

# hadolint ignore=DL3018
RUN apk add --no-cache curl unzip

# Set pipefail so curl | sha256sum pipe failures are caught
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint — binary verified against pinned SHA256 (MITRE T1195.002)
RUN curl -sSL https://github.com/hadolint/hadolint/releases/download/v2.14.0/hadolint-Linux-x86_64 \
        -o /usr/local/bin/hadolint && \
    echo "6bf226944684f56c84dd014e8b979d27425c0148f61b3bd99bcc6f39e9dc5a47  /usr/local/bin/hadolint" | sha256sum -c - && \
    chmod +x /usr/local/bin/hadolint

# gitleaks — binary verified against pinned SHA256 (MITRE T1195.002)
RUN curl -sSL https://github.com/gitleaks/gitleaks/releases/download/v8.30.0/gitleaks_8.30.0_linux_x64.tar.gz \
        -o /tmp/gitleaks.tar.gz && \
    echo "79a3ab579b53f71efd634f3aaf7e04a0fa0cf206b7ed434638d1547a2470a66e  /tmp/gitleaks.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks && \
    rm /tmp/gitleaks.tar.gz && \
    chmod +x /usr/local/bin/gitleaks

# opa — binary verified against pinned SHA256 (MITRE T1195.002)
RUN curl -sSL https://github.com/open-policy-agent/opa/releases/download/v1.14.0/opa_linux_amd64_static \
        -o /usr/local/bin/opa && \
    echo "15f38338fda46ce4feb9fedfbbc5aab80786ed925b340ba9b8065ba3dbdd0ce5 /usr/local/bin/opa" | sha256sum -c - && \
    chmod +x /usr/local/bin/opa

# tflint — binary verified against pinned SHA256 (MITRE T1195.002)
RUN curl -sSL https://github.com/terraform-linters/tflint/releases/download/v0.61.0/tflint_linux_amd64.zip \
        -o /tmp/tflint.zip && \
    echo "ca4e4e8cb7cc3436f2b6979e9c4fd4e2623a66fcca1ad1fe12f8669967636ae2  /tmp/tflint.zip" | sha256sum -c - && \
    unzip -q /tmp/tflint.zip -d /usr/local/bin/ && \
    rm /tmp/tflint.zip && \
    chmod +x /usr/local/bin/tflint

# Stage 2 — clean runtime, no curl
FROM python:3.13-alpine3.23@sha256:bb1f2fdb1065c85468775c9d680dcd344f6442a2d1181ef7916b60a623f11d40

# Copy only the verified binaries from builder — curl does not follow
COPY --from=builder /usr/local/bin/hadolint /usr/local/bin/
COPY --from=builder /usr/local/bin/gitleaks /usr/local/bin/
COPY --from=builder /usr/local/bin/opa /usr/local/bin/
COPY --from=builder /usr/local/bin/tflint /usr/local/bin/

# Stops .pyc files being written (path info leak, wasted bytes)
# Unbuffered output for CI log visibility
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Non-root system account — no password, no shell, no home dir (CIS Docker 4.1)
# UID chosen for k8s RunAsNonRoot
RUN addgroup -S -g 10001 lintgroup && \
    adduser -S -u 10001 lintuser -G lintgroup

# Standard application working directory
WORKDIR /app

# System dependencies — git and jq only, no curl
# hadolint ignore=DL3018
RUN apk add --no-cache \
    git \
    jq \
    bash

# Python linting tools — versions pinned in requirements.txt, managed by Dependabot
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    chown -R lintuser:lintgroup /app

# Drop root — all subsequent processes run as lintuser (Least Privilege)
USER lintuser

# Verify primary tool available (CIS Docker 4.6)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD hadolint --version || exit 1

# No fixed entrypoint — tool passed at runtime e.g. podman run lint-container yamllint file.yaml
CMD ["/bin/bash"]
