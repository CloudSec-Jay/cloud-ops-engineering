# SCP: Deny CloudTrail Disable and Modification

**File:** `deny_cloudtrail_disable.json`
**Scope:** AWS Organization — applies to all member accounts
**Type:** Service Control Policy (SCP)

---

## What This Does

Blocks any IAM principal in any member account from stopping CloudTrail logging, deleting a trail, or modifying a trail in ways that disable log file validation. The `SecurityAdmin` role is exempted as a break-glass principal for legitimate trail management.

An attacker's first move after gaining IAM access is to kill logging — this SCP makes that impossible for every principal except the explicitly named break-glass role.

---

## Line-by-Line Breakdown

```json
"Action": [
    "cloudtrail:DeleteTrail",
    "cloudtrail:StopLogging",
    "cloudtrail:UpdateTrail"
]
```

Three actions, each covering a distinct attacker behavior:

**`cloudtrail:StopLogging`** — pauses event delivery without removing the trail configuration. The trail still exists, but no API calls are recorded. This is the quietest option — no trail is deleted, no alarm fires on trail deletion. Maps to T1562.008.

**`cloudtrail:DeleteTrail`** — permanently removes the trail and stops all logging. More destructive than StopLogging. Maps to both T1562.008 (impair defenses) and T1485 (data destruction) — the trail configuration itself is destroyed, not just paused.

**`cloudtrail:UpdateTrail`** — modifies trail configuration. An attacker can call this with `EnableLogFileValidation: false` to disable log integrity checking without stopping the trail. Logs keep flowing, but tampered log files will no longer be detected. This is the subtlest of the three — logging appears operational while integrity is silently disabled.

---

```json
"Resource": "*"
```

Required field. SCPs do not support resource-level scoping the same way IAM policies do — `*` is the correct and only valid value. A Statement without `Resource` is invalid and AWS rejects the policy.

---

```json
"Condition": {
    "StringNotLike": {
        "aws:PrincipalArn": "arn:aws:iam::*:role/SecurityAdmin"
    }
}
```

**`StringNotLike`** — fires the Deny for every principal whose ARN does NOT match the pattern. Anyone who is not `SecurityAdmin` is denied. Same exemption pattern as `deny_public_s3.json`.

**`aws:PrincipalArn`** — global condition key that evaluates to the full ARN of the calling identity at request time.

**`arn:aws:iam::*:role/SecurityAdmin`** — the `*` in the account ID position matches any account in the organization. The `SecurityAdmin` role in any member account is exempted, not just one specific account. Tighten to a specific account ID if this needs to be more restrictive.

---

## What This SCP Does Not Cover

Two gaps identified during design — both require separate controls:

**CloudTrail Channels (`cloudtrail:DeleteChannel`, `cloudtrail:UpdateChannel`)**
CloudTrail Lake uses channels to deliver events to external partner services (Splunk, Datadog, custom HTTPS endpoints). Disabling a channel cuts off event delivery to those destinations without touching the standard trail. This SCP does not block channel modification. If CloudTrail Lake integrations are in use, add these two actions to the policy.

**S3 Log Deletion (`s3:DeleteObject` on the logging bucket)**
This SCP stops trail-level tampering. It does not prevent an attacker from going directly to the S3 bucket where CloudTrail logs are delivered and deleting the log objects. That maps to T1070.004 — Indicator Removal: File Deletion. The control for that gap is S3 Object Lock (COMPLIANCE mode) on the logging bucket combined with a restrictive bucket policy. Those are separate artifacts.

---

## Real-World Breaches

### T1562.008 — Impair Defenses: Disable or Modify Cloud Logs

**Story 1 — TeamTNT (2020)**
TeamTNT targeted AWS environments by harvesting credentials from misconfigured Docker daemons and exposed `.env` files. After obtaining IAM keys, their tooling called `cloudtrail:StopLogging` as one of the first automated steps — before deploying crypto miners or exfiltrating data. With logging stopped, there was no CloudTrail evidence of the miner deployment, no GuardDuty findings sourced from CloudTrail events, and no Wazuh triggers. Victim accounts ran miners for extended periods before detection via billing anomalies rather than security events.
- Source: [Trend Micro — TeamTNT's Extended Credential Theft Campaign](https://www.trendmicro.com/en_us/research/20/i/teamtnt-now-deploying-ddos-capable-irc-bot-tnt-miner.html)

**Story 2 — Pacu Framework CloudTrail Disruption**
Pacu is an open-source AWS exploitation framework used in authorized penetration tests and, in the wild, by attackers. Its `cloudtrail__disable_disruption` module enumerates all trails across all regions and either stops logging or calls `UpdateTrail` to disable log file validation. The module is specifically designed to be subtle — `UpdateTrail` leaves the trail running so defenders see no deletion alert, but log integrity cannot be verified. This is why `UpdateTrail` must be blocked alongside the more obvious `StopLogging`.
- Source: [Pacu GitHub — cloudtrail__disable_disruption](https://github.com/RhinoSecurityLabs/pacu)

**Story 3 — Credential Compromise → Log Suppression → S3 Exfil**
A documented pattern in cloud incident reports: attacker gains IAM access via exposed keys in a public GitHub repository, calls `cloudtrail:StopLogging` across all regions (not just the default), then enumerates and exfiltrates S3. The multi-region stop is significant — many environments only have CloudTrail enabled in one region. An attacker operating in `us-west-2` while only `us-east-1` is logged has already bypassed detection. This SCP blocks the API call regardless of which region the attacker targets.
- Source: [GitHub — aws-customer-security-incidents](https://github.com/ramimac/aws-customer-security-incidents)

---

### T1485 — Data Destruction

**Story 1 — DeleteTrail as scorched earth**
In post-incident forensic reviews, `cloudtrail:DeleteTrail` appears in attacker timelines not as a stealth move but as a final action before exiting — destroying the audit record of the attack itself. Unlike `StopLogging` (which can be restarted with logs intact), `DeleteTrail` removes the trail configuration. Any events not yet delivered to S3 are lost. The forensic record of how the attacker moved is gone.

**Story 2 — Ransomware precursor in cloud environments**
Cloud-targeting ransomware operators have used CloudTrail deletion in the same playbook as on-premises ransomware actors disabling Windows Event Log. Kill logging, encrypt or delete data, demand ransom. Without the trail, the victim cannot reconstruct what data was accessed before encryption. `DeleteTrail` maps directly to data destruction intent in this context.

**Story 3 — Insider threat log destruction**
In a documented insider threat case, a privileged IAM user called `cloudtrail:DeleteTrail` on the day they submitted their resignation — deleting the trail covering the previous 90 days of their activity. The organization had no S3 Object Lock on the logging bucket and no SCP blocking trail deletion. The forensic investigation had no CloudTrail evidence to reconstruct the timeline of data access.

---

## Defense-in-Depth Stack

| Control | What it prevents |
|---------|-----------------|
| This SCP | Blocks trail stop, deletion, and validation bypass org-wide |
| S3 Object Lock (COMPLIANCE) | Prevents log file deletion from the S3 bucket after delivery |
| CloudTrail log file validation | Detects tampered log files (blocked from being disabled by this SCP) |
| GuardDuty | Detects anomalous API calls even without CloudTrail (uses VPC flow + DNS) |
| SNS alert on `StopLogging` | Real-time notification if the break-glass role is used |
| Multi-region trail | Ensures logging in every region, not just the default |

---

## Framework Mapping

| Framework | Control | Rationale |
|-----------|---------|-----------|
| MITRE ATT&CK | T1562.008 — Impair Defenses: Disable or Modify Cloud Logs | Primary mitigation — blocks the three API calls attackers use to kill CloudTrail |
| MITRE ATT&CK | T1485 — Data Destruction | `DeleteTrail` destroys the trail configuration itself, not just pauses it |
| MITRE ATT&CK | T1070.004 — Indicator Removal: File Deletion | Gap — out of scope for this SCP; covered by S3 Object Lock on the logging bucket |
| OWASP Top 10:2025 | A09:2025 — Security Logging and Monitoring Failures | Disabling CloudTrail is the direct exploitation of a logging failure |
| STRIDE | Repudiation | Destroying audit logs removes the ability to attribute actions — attacker denies all activity |
