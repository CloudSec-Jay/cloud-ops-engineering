# Observability Compose Stack

This development stack combines Prometheus, Loki, and Grafana for local metrics, logs, and dashboard experimentation.

## Current endpoints

| Service | Host binding | Notes |
|---|---|---|
| Prometheus | `127.0.0.1:9090` | Scrapes only itself in the current configuration |
| Loki | `127.0.0.1:3100` | No log shipper is included |
| Grafana | `0.0.0.0:3000` | Set `GRAFANA_PASSWORD`; restrict exposure before use |

## Start and validate

```bash
cd containers/compose/observability
export GRAFANA_PASSWORD='replace-locally'
docker compose config --quiet
docker compose up -d
docker compose ps
```

## Known gaps

- Images use mutable tags.
- Grafana is not loopback-only in the current file.
- Loki has no persistent volume or explicit configuration.
- No log collector, alert rules, notification routing, or dashboard provisioning is included.
- Resource settings must be confirmed against the target Compose implementation.

Add authentication, TLS, backups, retention, alerting, and tested resource limits before treating this as more than a local example.
