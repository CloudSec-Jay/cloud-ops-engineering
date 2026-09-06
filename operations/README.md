# Operations

Operational procedures connect telemetry and configuration changes to triage, containment, recovery, and evidence.

## Components

- [`monitoring/`](monitoring/README.md): Wazuh configuration, detections, integrations, tuning, and dashboards
- [`incident-response/`](incident-response/README.md): evidence collection, host-compromise response, Wazuh triage, and hardening recovery

## Operating expectations

- Define ownership, severity, escalation, and recovery for actionable alerts.
- Preserve evidence before containment or cleanup.
- Test positive and negative detection cases.
- Treat active response, teardown, cleanup, and host-hardening scripts as privileged changes.
- Record known false positives and tuning decisions instead of silently disabling alerts.
- Keep operational credentials, enrollment keys, certificates, and raw sensitive evidence outside Git.
