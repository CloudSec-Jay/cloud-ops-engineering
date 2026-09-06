# Operational Evidence: [Change or Control Name]

**Owner:** [team or person]
**Environment:** [development / staging / production]
**Date:** [YYYY-MM-DD]
**Related artifact:** `path/to/artifact`

## Objective

[Describe the operational outcome, risk, or control being validated.]

## Scope

- Included systems: [accounts, hosts, clusters, or services]
- Excluded systems: [explicit exclusions]
- Change or test window: [start and end]

## Preconditions

- [Required access, test data, backups, or approvals]
- [Expected baseline state]

## Validation procedure

1. [Command or inspection step]
2. [Positive test]
3. [Negative or failure-path test]
4. [Rollback or recovery check]

Do not place credentials, private keys, session tokens, account IDs, or unredacted sensitive logs in this document.

## Results

| Check | Expected | Observed | Result |
|---|---|---|---|
| [check] | [expected state] | [observed state] | Pass / Fail / Not run |

## Evidence references

| Evidence | Location | Retention |
|---|---|---|
| [redacted log, CI run, screenshot, or output] | [link or approved evidence store] | [period] |

## Risks and gaps

- [Known limitation, untested path, or accepted risk]
- [Required follow-up and owner]

## Rollback and recovery

[State the rollback trigger, commands or procedure, owner, and method used to confirm recovery.]

## Framework mapping

Map only when the artifact provides direct evidence. A mapping is not a compliance claim.

| Framework | Identifier | Evidence relationship |
|---|---|---|
| [NIST / MITRE ATT&CK / OWASP / STRIDE] | [verified identifier] | [specific evidence] |
