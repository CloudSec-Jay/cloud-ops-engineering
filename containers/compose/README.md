# Compose Services

Each subdirectory is an independent service stack.

| Stack | Purpose | Exposure in current file | Status |
|---|---|---|---|
| [`authelia/`](authelia/README.md) | Authentication gateway scaffold | `127.0.0.1:9091` | Incomplete configuration |
| [`code-server/`](code-server/README.md) | Local browser-based development environment | `127.0.0.1:8080` | Local example |
| [`observability/`](observability/README.md) | Prometheus, Loki, and Grafana | Prometheus/Loki local; Grafana all interfaces | Development example |
| [`wazuh-single-node/`](wazuh-single-node/README.md) | Wazuh manager, indexer, and dashboard | Multiple host ports | Lab deployment |

Validate a stack before starting it:

```bash
docker compose -f PATH/TO/compose.yml config --quiet
```

The current files are portfolio examples. They require version pinning, secrets configuration, network review, persistent-data planning, and target-host testing before production use.
