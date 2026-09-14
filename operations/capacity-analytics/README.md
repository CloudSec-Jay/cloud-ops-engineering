# EC2 Fleet Capacity Analytics

This project is building a local-first EC2 inventory and capacity analytics workflow. Synthetic data must work end to end before the collector receives AWS access or any billable AWS resources are created.

## Current status

Implemented in the repository:

- a Docker Compose stack with MySQL 8.4.11 and Grafana
- an external MySQL volume named `mysql_data`
- loopback-only host bindings for MySQL and Grafana
- migrations for `collection_runs` and `instances`
- smoke and negative constraint tests for `collection_runs`
- architecture and database-security design notes

Not yet implemented or validated:

- automated CI validation for this Compose file
- runtime constraint tests for `instances`
- the `inventory_snapshots` migration and its foreign keys
- separate migration, collector, and read-only Grafana database accounts
- Grafana data-source and dashboard provisioning
- container health checks, backup/restore tests, and a pinned Grafana image version
- the synthetic/Python collector and read-only AWS collection mode

## Layout

```text
capacity-analytics/
|-- compose.yaml
|-- db/migrations/
|-- docs/architecture.md
|-- tests/sql/
|-- secrets/              local and ignored
`-- vars/                 local Ansible Vault material and ignored
```

## Local stack

Run commands from this directory so the relative secret path resolves correctly. The local file `secrets/mysql_root_password` must exist and must remain outside Git.

The Compose definition treats `mysql_data` as an external volume. Confirm an existing volume before reusing it, or create a new empty volume only when a fresh database is intended:

```bash
docker volume inspect mysql_data
docker compose config
docker compose up -d
docker compose ps
```

MySQL listens on `127.0.0.1:3306`. Grafana listens on `127.0.0.1:3000`. Within the Compose network, other services will reach MySQL through `db:3306` rather than `localhost`.

## Database changes

Apply migrations in numeric order to a disposable database first. Current files are:

1. `db/migrations/001_initial_schema.sql`
2. `db/migrations/002_create_instances.sql`

SQL tests use transactions and rollback so test rows do not remain. Expected constraint errors are successful negative-test results only when the final row-count checks confirm that invalid rows were rejected.

## Ownership boundary

Docker Compose is the canonical owner of the local MySQL and Grafana containers. Do not run the legacy standalone Ansible MySQL playbook against the same Docker engine at the same time. Ansible remains planned for later host configuration through Systems Manager.

## Stop and recover

```bash
docker compose down
```

Do not add `--volumes` unless deletion of local MySQL and Grafana data is explicitly intended. Backups are not considered proven until a restore has been tested.
