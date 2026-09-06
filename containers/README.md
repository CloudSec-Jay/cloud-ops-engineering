# Containers

This area contains containerized operational services and repeatable tool environments. Cloud resources and configuration management remain under [`infrastructure/`](../infrastructure/README.md).

## Contents

- [`compose/`](compose/README.md): Authelia, code-server, observability, and Wazuh service stacks
- [`images/`](images/README.md): lint and cloud-operations toolbox build contexts
- [`quadlets/wazuh/`](quadlets/wazuh/README.md): systemd-managed Wazuh services for Podman

## Baseline workflow

Run Compose commands from the stack directory so relative mounts and secret paths resolve correctly:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose logs --follow
docker compose down
```

Before deployment, replace mutable image tags with reviewed versions or digests, confirm every published port, set resource limits, and prepare backup and rollback procedures for persistent volumes.

Never commit populated environment files, generated certificates, or files under a `secrets/` directory.
