# Wazuh Single-Node Compose Stack

This lab stack runs Wazuh manager, indexer, and dashboard containers using the versions declared in `docker-compose.yml`.

## Prerequisites

- Linux host with Docker Engine and the Compose plugin
- Sufficient memory and storage for OpenSearch/Wazuh
- `vm.max_map_count=262144`
- Local credentials in `.env`

## Prepare

```bash
cd containers/compose/wazuh-single-node
cp .env.example .env
```

Populate the required Wazuh passwords. If AWS ingestion is enabled, prefer a short-lived role-based credential source; never commit AWS credentials. Passwords must remain consistent with the hashes configured in `config/wazuh_indexer/internal_users.yml`.

Generate indexer certificates and validate the stack:

```bash
sudo sysctl -w vm.max_map_count=262144
docker compose -f generate-indexer-certs.yml run --rm generator
docker compose config --quiet
```

## Start and inspect

```bash
docker compose up -d
docker compose ps
docker compose logs --follow
```

The manager enrollment, syslog, API, indexer, and dashboard ports are published by the current Compose file. Review firewall rules and bind addresses before using the stack on a shared host.

## Stop and recover

```bash
docker compose down
```

Do not add `--volumes` unless permanent deletion of indexed alerts and configuration data is intended. Back up persistent volumes and generated certificates before upgrades or teardown.

This stack requires target-host testing. A successful `docker compose config` check proves only that Compose can parse the configuration.
