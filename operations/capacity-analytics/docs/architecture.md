# EC2 Fleet Capacity Analytics Architecture

## Purpose

This project builds an evidence-based view of a small EC2 fleet. It will answer what instances exist, how much capacity is ready or unavailable, how resources are used over time, and which capacity changes deserve investigation.

The first implementation is a local learning environment. It must work with synthetic data before it connects to AWS or creates billable resources.

## Current state

Docker Compose is the canonical owner of the local management stack. It runs MySQL 8.4.11 and Grafana, persists their data in Docker volumes, and binds ports 3306 and 3000 to localhost rather than all host interfaces.

The repository currently contains migrations for `collection_runs` and `instances`, plus smoke and negative constraint tests for `collection_runs`. Runtime tests for `instances`, the `inventory_snapshots` migration, synthetic data generator, collector, Grafana provisioning, and capacity-specific AWS infrastructure remain planned.

## Component responsibilities

| Component | Responsibility |
| --- | --- |
| Docker Compose | Create and operate the local MySQL and Grafana containers |
| Ansible | Later configure EC2 workers through SSM; the standalone MySQL playbook is legacy and is not the canonical local stack |
| MySQL | Store inventory, observations, metrics, experiments, and analytical results |
| SQL migrations | Define versioned tables, relationships, constraints, indexes, and views |
| Python collector | Read scoped EC2 and CloudWatch data and write normalized observations |
| Grafana | Query MySQL through a read-only account and display capacity dashboards |
| Terraform | Prepare reviewable AWS networking, IAM, EC2, storage, and tagging configuration |

## Data flow

```text
Local demo:
synthetic fixture generator -> MySQL -> SQL views -> Grafana

Future AWS collection:
EC2 API -----------+
                   +-> Python collector -> MySQL -> SQL views -> Grafana
CloudWatch API ----+
```

Collection is read-only. It will select resources by project tags and will not start, stop, resize, or terminate instances.

## Trust and deployment boundaries

The local machine is the management host. MySQL, the future collector, and Grafana are management services and do not count toward workload capacity.

MySQL remains accessible only from localhost and the private Docker network. The current root password is supplied through a local ignored Compose secret file. Planned migration, collector, and Grafana accounts will have separate permissions, with Grafana restricted to read-only access. The capacity-local Ansible Vault file is retained from the earlier Ansible experiment; it is not referenced by the current Compose stack and is not the Compose credential source.

The future AWS fleet will use a dedicated non-production account or environment, one configurable region, consistent project tags, encrypted EBS volumes, IMDSv2, and Systems Manager instead of inbound SSH. Terraform planning and cost review must occur before any AWS deployment, and deployment requires explicit approval.

## Database security design

Database security is organized around confidentiality, integrity, and availability.

| Goal | Current controls | Planned controls |
| --- | --- | --- |
| Confidentiality | MySQL and Grafana bind to localhost; the MySQL root password is supplied through an ignored local Compose secret file | Separate migration, collector, and Grafana accounts; read-only Grafana access; TLS for any future non-local connection |
| Integrity | InnoDB tables, primary keys, check constraints, versioned migrations, and rollback-based SQL tests | Foreign keys, parameterized collector queries, and data-quality views |
| Availability | Persistent Docker storage, Compose restart policies, and explicit CPU/memory limits | Container health checks, monitored collection failures, and tested backup and restore procedures |

The MySQL root account is reserved for local administration and migration bootstrap. Application services must not use it. The collector will receive only the database permissions needed to insert and update collected observations, while Grafana will receive select access to approved tables or views.

Database dumps, Docker volumes, connection strings, real AWS identifiers, and credentials must remain outside Git. Logs must not contain database passwords, AWS credentials, or secret-bearing queries. Synthetic and AWS-sourced records remain visibly distinguishable.

Access to the Docker daemon is treated as privileged host access. MySQL is pinned to an explicit version; Grafana is not yet pinned and must be pinned before shared or production-like use. Images are updated intentionally after vulnerability review. If MySQL later accepts traffic beyond localhost or the private container network, authenticated TLS becomes required rather than optional.

Backups are not considered proven until restoration is tested. Teardown procedures must identify the exact database and volume, confirm whether analytical history requires preservation, and require explicit approval before deletion.

## Initial data model

The initial data model contains three related tables. Two are currently implemented and one remains planned:

- `collection_runs` is implemented and records the scope, timing, status, coverage, and errors for each collection attempt.
- `instances` is implemented and stores the durable AWS identity and descriptive tags for each discovered EC2 instance.
- `inventory_snapshots` is planned and will store the state, health, readiness, and capacity observed for an instance at a specific time.

One instance can have many snapshots, and one collection run can produce many snapshots. Snapshot rows retain instance type, vCPU count, and memory at observation time so historical reports remain correct after resizing.

Timestamps are stored in UTC. Memory is stored as integer MiB to avoid rounding. Missing data remains unknown rather than being converted to zero or healthy. Every demo or collected record identifies its origin as `synthetic` or `aws`.

## Planned increments

1. Re-run and record validation for `collection_runs` and add runtime tests for `instances`.
2. Add and validate the `inventory_snapshots` migration and foreign keys.
3. Load repeatable synthetic inventory and verify capacity queries by hand.
4. Add metric samples and capacity-weighted analytical views.
5. Provision a read-only Grafana data source and inventory dashboard.
6. Add the Python collector in an explicit demo mode.
7. Prepare capacity-specific Terraform and Ansible for AWS review without applying resources.
8. Estimate costs, review the Terraform plan, and deploy only after approval.

## Recovery and teardown

Stopping or replacing the MySQL container does not remove its named volume. Local database deletion requires an explicit volume-removal command and is treated as destructive. Before a future AWS teardown, analytical data must be backed up and all billable resources, including EBS volumes and public IPv4 addresses, must be reviewed.
