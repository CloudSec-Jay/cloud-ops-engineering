# Wazuh Operations and Detection

Wazuh examples for Linux endpoint monitoring, AWS ingestion, file-integrity detection, security configuration assessment, tuning, dashboards, and incident-response integration.

## Layout

| Directory | Purpose | Current status |
|---|---|---|
| `agent-configs/` | Endpoint configuration examples | Requires host-specific review |
| `manager-configs/` | Manager and shared group configuration | Contains deployment placeholders |
| `rules/` | Linux file-integrity rules `100002` through `100007` | Requires rule testing |
| `sca/` | Fedora CIS-oriented assessment policy | Large custom policy; verify benchmark applicability |
| `tuning/` | FIM overrides and suppression decisions | Review with representative events |
| `integrations/` | AWS, Docker, and VirusTotal notes/configuration | Mixed maturity |
| `active-response/` | Privileged response prototypes | Do not enable without code repair and testing |
| `runbooks/` | Alert-specific response guidance | Partial coverage |
| `dashboards/` | Dashboard design notes | No exported dashboard object yet |
| `deploy/` | Deployment and teardown wrappers | Privileged and potentially destructive |
| `evidence/` | Redacted tuning and monitoring observations | Examples, not production proof |

## Current rule coverage

The custom XML rules monitor executable permission changes, scripts staged in temporary paths, and changes to sudoers, SSH authorized keys, and PAM configuration. MITRE ATT&CK mappings in the rule files must be rechecked when rule behavior changes.

## Validation

```bash
xmllint --noout operations/monitoring/wazuh/rules/*.xml
bash -n operations/monitoring/wazuh/active-response/remove-threat.sh
```

Use Wazuh's configuration and rule-testing tooling with representative positive and negative events before deployment. Wazuh configuration can contain multiple `<ossec_config>` fragments, so a generic single-document XML parser is not sufficient. XML parsing alone does not prove that decoders, parent rules, field names, or frequency correlation behave as intended.

## Important limitations

- `active-response/executable_perm.py` changes file attributes and depends on local allowlist/approval configuration.
- `active-response/remove-threat.sh` deletes a detected file instead of quarantining it.
- Example manager configuration contains placeholders and must not receive committed credentials.

Pair alerts with [`../../incident-response/`](../../incident-response/README.md) procedures and preserve evidence before remediation.
