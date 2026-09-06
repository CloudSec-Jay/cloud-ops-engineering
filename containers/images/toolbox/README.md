# Cloud Operations Toolbox

A Linux AMD64 execution environment for AWS, infrastructure provisioning, configuration management, artifact signing, and vulnerability scanning.

## Included tools

- AWS CLI v2
- Terraform and Packer
- Ansible, boto3, Checkov, and hvac
- Trivy and cosign
- Git and standard certificate support

Exact versions and standalone-binary hashes are defined in [`Dockerfile`](Dockerfile) and [`requirements.txt`](requirements.txt). The AWS CLI installer is downloaded from AWS but is not currently checked against a pinned checksum; treat that as a supply-chain gap.

## Build and use

```bash
docker build -t cloud-ops-toolbox containers/images/toolbox
docker run --rm -v "$PWD:/app" -w /app cloud-ops-toolbox terraform version
docker run --rm -v "$PWD:/app" -w /app cloud-ops-toolbox ansible-playbook --syntax-check infrastructure/ansible/playbooks/PLAYBOOK.yml
docker run --rm -v "$PWD:/app:ro" -w /app cloud-ops-toolbox trivy fs .
```

Pass cloud authentication at runtime using a short-lived mechanism. Avoid baking credentials into the image or mounting an entire home directory. Socket access such as `/var/run/docker.sock` grants substantial host control and should not be used by default.

The runtime uses numeric UID/GID `10001:10001`. Confirm mounted-file permissions on the host before relying on write access.
