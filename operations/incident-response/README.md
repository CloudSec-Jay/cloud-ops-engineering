# Incident Response

This area contains procedures for responding to Linux and Wazuh events while preserving useful evidence.

## Contents

- [`evidence/evidence-collection.md`](evidence/evidence-collection.md): evidence collection and integrity guidance
- [`playbooks/linux-host-compromise.md`](playbooks/linux-host-compromise.md): Linux host triage, containment, eradication, and recovery
- [`runbooks/wazuh-alert-triage.md`](runbooks/wazuh-alert-triage.md): general Wazuh alert workflow
- [`runbooks/fedora-cis-hardening.md`](runbooks/fedora-cis-hardening.md): recovery guidance for Fedora hardening changes

## Use

Adapt commands to the affected system and obtain the required authority before collection or containment. Store raw evidence in an approved evidence location, record timestamps in UTC, calculate hashes where appropriate, and document every action taken.

Do not commit host images, memory captures, credentials, tokens, personal data, or unredacted production logs to this repository.
