# Monitoring and Detection

This area connects AWS and Linux telemetry to Wazuh rules, triage procedures, tuning decisions, and optional response actions.

## Event path

```text
AWS and Linux telemetry
  -> collection and transport
  -> Wazuh manager decoding and rules
  -> indexed alert and dashboard
  -> analyst triage
  -> evidence preservation
  -> reviewed containment or recovery
```

## Components

- [`wazuh/`](wazuh/README.md): manager and agent examples, custom rules, SCA, integrations, and operational notes
- [`../incident-response/`](../incident-response/README.md): evidence, triage, containment, and recovery procedures

## Detection quality bar

Every production detection should document:

- behavior and log source
- triggering fields and assumptions
- severity and response target
- likely false positives and evasion gaps
- positive and negative test cases
- triage and escalation procedure
- evidence-retention requirements

Active response should be the exception. Start with alert-only behavior, measure signal quality, preserve evidence, and require explicit review before enabling commands that change permissions, lock files, block networks, or delete content.

## In-scope next work

- Add repeatable rule tests and representative sanitized log fixtures.
- Add service health, disk capacity, ingestion lag, and queue-backpressure alerts.
- Add SLOs and notification routing with ownership and escalation windows.
- Add append-only or externally retained alert evidence.
- Replace long-lived AWS ingestion credentials with a suitable short-lived identity mechanism.
