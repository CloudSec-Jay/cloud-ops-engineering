# Toolbox Container
# CIS Docker 4.1 - Non-root user
# CIS Docker 4.3 - Pinned base image digest
# NIST 800-190 - Immutable infrastructure

# Stage 1 — Download, verify, and extract all tools
FROM debian:trixie-20260824-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132 AS builder

# Set pipefail so curl | sha256sum pipe failures are caught
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build dependencies (ca-certificates needed for HTTPS downloads)
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    tar \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# trivy — binary verified against pinned SHA256 (MITRE T1195.002)
RUN curl -sSL https://github.com/aquasecurity/trivy/releases/download/v0.69.3/trivy_0.69.3_Linux-64bit.tar.gz \
        -o /tmp/trivy.tar.gz && \
    echo "1816b632dfe529869c740c0913e36bd1629cb7688bd5634f4a858c1d57c88b75  /tmp/trivy.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/trivy.tar.gz -C /usr/local/bin trivy && \
    rm /tmp/trivy.tar.gz && \
    chmod +x /usr/local/bin/trivy

# cosign — binary verified against pinned SHA256 (MITRE T1195.002)
RUN curl -sSL https://github.com/sigstore/cosign/releases/download/v3.0.5/cosign-linux-amd64 -o /usr/local/bin/cosign && \
    echo "db15cc99e6e4837daabab023742aaddc3841ce57f193d11b7c3e06c8003642b2  /usr/local/bin/cosign" | sha256sum -c - && \
    chmod +x /usr/local/bin/cosign

# terraform — binary verified against pinned SHA256 (MITRE T1195.002)
RUN curl -sSL https://releases.hashicorp.com/terraform/1.14.6/terraform_1.14.6_linux_amd64.zip \
        -o /tmp/terraform.zip && \
    echo "364c6ee08b0cb8fcbb28a115aacb2aa48e88abc56c149170bd65c2f75d98ea8d  /tmp/terraform.zip" | sha256sum -c - && \
    unzip -q /tmp/terraform.zip -d /usr/local/bin/ && \
    rm /tmp/terraform.zip && \
    chmod +x /usr/local/bin/terraform

# packer — binary verified against pinned SHA256 (MITRE T1195.002)
RUN curl -sSL https://releases.hashicorp.com/packer/1.15.0/packer_1.15.0_linux_amd64.zip \
        -o /tmp/packer.zip && \
    echo "2fd1149c5c6c7604ced64d7b56638af05f6b7ed3f6835182bc913ddaba1f16b8  /tmp/packer.zip" | sha256sum -c - && \
    unzip -q /tmp/packer.zip packer -d /usr/local/bin/ && \
    rm /tmp/packer.zip && \
    chmod +x /usr/local/bin/packer

# AWS CLI v2 — official installer isolates files to specific directories
RUN curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli

# =========================================================================

# Stage 2 — Clean runtime, no curl, no apt repositories
FROM debian:trixie-20260824-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

# Minimal runtime dependencies
# git: required by TF modules and Ansible
# less: required by AWS CLI for log pagination
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    git \
    less \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy verified standalone binaries from builder
COPY --from=builder /usr/local/bin/trivy /usr/local/bin/
COPY --from=builder /usr/local/bin/cosign /usr/local/bin/
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/
COPY --from=builder /usr/local/bin/packer /usr/local/bin/

# Copy compiled AWS CLI directories from builder and recreate symlinks
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws && \
    ln -s /usr/local/aws-cli/v2/current/bin/aws_completer /usr/local/bin/aws_completer

# Set up Python Virtual Environment (Bypasses Debian PEP 668 restrictions safely)
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Non-root system user (CIS Docker 4.1)
RUN groupadd -g 10001 toolgroup && \
    useradd -r -u 10001 -m -d /home/tooluser -g toolgroup tooluser

# Standard application working directory
WORKDIR /app

# Python tools managed via Dependabot
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Transfer ownership of workspace and venv before dropping privileges
RUN chown -R 10001:10001 /app \
    && chown -R 10001:10001 /opt/venv

# Drop root (Least Privilege)
USER 10001:10001

# Verify primary tool available (CIS Docker 4.6)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD trivy --version || exit 1

CMD ["/bin/bash"]
