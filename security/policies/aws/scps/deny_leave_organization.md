# SCP: Deny Leave Organization

**File:** `deny_leave_organization.json`
**Scope:** AWS Organization — applies to all member accounts
**Type:** Service Control Policy (SCP)

---

## What This Does

Blocks any IAM principal in any member account from removing that account from the AWS Organization. No break-glass exemption exists — there is no legitimate reason for any principal inside a member account to call this action.

One API call removes every org-level guardrail simultaneously: SCPs, GuardDuty delegated admin, Security Hub, AWS Config aggregation, and CloudTrail org-level trails. This SCP makes that impossible from inside any member account.

---

## Line-by-Line Breakdown

```json
"Sid": "DenyLeaveOrg"
```
Statement ID — human-readable label for auditing and CloudTrail filtering. No functional effect.

---

```json
"Effect": "Deny"
```
Explicit deny. In AWS, an explicit Deny always wins over any Allow — no IAM policy inside the account can override it.

---

```json
"Action": [
    "organizations:LeaveOrganization"
]
```
The single API call a member account can make to remove itself from the organization. This is distinct from `organizations:RemoveAccountFromOrganization` — that action is called from the management account and is not blockable by SCPs. `LeaveOrganization` is the only org-structure action available to member accounts, making this SCP's scope precise.

---

```json
"Resource": "*"
```
Required field — a Statement without `Resource` is invalid. `*` is the correct value; SCPs do not support resource-level scoping.

---

## Why There Is No Condition Block

Every other SCP in this set includes a `StringNotLike` condition to exempt a break-glass role. This one does not — intentionally.

`LeaveOrganization` has no legitimate use case from inside a member account. If the organization needs to remove an account, that operation (`organizations:RemoveAccountFromOrganization`) is performed from the management account, which SCPs cannot touch. Adding a condition exemption here would create a privileged role an attacker could specifically target to bypass this control. Blanket deny with no exceptions is the correct design.

---

## What Happens When a Member Account Leaves the Org

The moment `organizations:LeaveOrganization` succeeds:

| Control Lost | Impact |
|--------------|--------|
| All SCPs | Every org-level deny is immediately removed |
| GuardDuty delegated admin | Security team loses threat detection visibility into the account |
| Security Hub | Centralized findings from that account stop flowing |
| AWS Config aggregator | Compliance and drift detection severed |
| CloudTrail org trail | If using an org-level trail, that account's events stop flowing to the central logging bucket |
| IAM Identity Center | SSO access may break depending on configuration |

The account becomes an unmonitored island. An attacker operating inside it has no org-level guardrails constraining their actions.

---

## Technique Evidence

> **Note:** No public incident report has named `organizations:LeaveOrganization` as a confirmed attacker action. This is a documented attack path — the risk is real and the technique is implemented in offensive tooling — but breach evidence below maps to the underlying MITRE techniques, not this specific API call.
>
> Sources: [Pacu — org__enum_orgs module](https://github.com/RhinoSecurityLabs/pacu) documents org egress as an implemented attack technique. [MITRE ATT&CK T1578](https://attack.mitre.org/techniques/T1578/), [T1098](https://attack.mitre.org/techniques/T1098/), [T1531](https://attack.mitre.org/techniques/T1531/), [T1490](https://attack.mitre.org/techniques/T1490/) each contain confirmed procedure examples from named threat groups.

---

### T1578 — Modify Cloud Compute Infrastructure

Real breaches using this technique involved attackers modifying cloud infrastructure to expand access after initial compromise — spinning up EC2 instances in unapproved regions, modifying VPC configurations, and creating new compute resources to establish persistence. The `LeaveOrganization` vector achieves the same outcome by removing the SCP guardrails that would otherwise block those actions.

- [MITRE ATT&CK T1578 — Procedure Examples](https://attack.mitre.org/techniques/T1578/)

---

### T1098 — Account Manipulation

TeamTNT (2020) and subsequent crypto-mining campaigns manipulated IAM accounts after credential compromise — creating new IAM users, attaching AdministratorAccess, and establishing persistence before the legitimate owner could respond. `LeaveOrganization` accelerates this: once outside the org, `deny_iam_user_creation` and other SCPs no longer apply, and those IAM manipulation techniques become available.

- [Trend Micro — TeamTNT Account Manipulation](https://www.trendmicro.com/en_us/research/20/i/teamtnt-now-deploying-ddos-capable-irc-bot-tnt-miner.html)
- [MITRE ATT&CK T1098 — Procedure Examples](https://attack.mitre.org/techniques/T1098/)

---

### T1531 — Account Access Removal

Lapsus$ (2022) severed legitimate administrator access as part of their attack pattern — modifying MFA settings and account configurations to lock out the security team during active incidents. The `LeaveOrganization` vector achieves the same outcome at org scale: GuardDuty delegated admin, Security Hub, and CloudTrail org trail all lose visibility into the account simultaneously.

- [CISA Advisory AA22-181A — Lapsus$](https://www.cisa.gov/news-events/cybersecurity-advisories/aa22-181a)
- [MITRE ATT&CK T1531 — Procedure Examples](https://attack.mitre.org/techniques/T1531/)

---

### T1490 — Inhibit System Recovery

NotPetya (2017) and subsequent ransomware campaigns deleted Windows Volume Shadow Copies to prevent recovery before encrypting data. Cloud equivalents follow the same pattern — removing backup policies, Config remediation rules, and automated response mechanisms before executing destructive actions. An account that leaves the org loses all org-managed recovery controls before the primary objective executes.

- [CISA — NotPetya Advisory](https://www.cisa.gov/news-events/alerts/2017/06/28/petya-ransomware)
- [MITRE ATT&CK T1490 — Procedure Examples](https://attack.mitre.org/techniques/T1490/)

---

## Defense-in-Depth Stack

| Control | What it prevents |
|---------|-----------------|
| This SCP | Blocks `LeaveOrganization` from inside any member account |
| CloudTrail alerting on `LeaveOrganization` | Detects any attempt — even failed ones blocked by this SCP |
| GuardDuty | Detects the credential compromise that would precede this action |
| MFA on privileged roles | Raises the bar for an attacker to reach admin-level permissions |
| Management account SCPs | `RemoveAccountFromOrganization` controlled separately from the management account |

---

## Framework Mapping

| Framework | Control | Rationale |
|-----------|---------|-----------|
| MITRE ATT&CK | T1578 — Modify Cloud Compute Infrastructure | Removing the account restructures the cloud environment and removes all guardrails |
| MITRE ATT&CK | T1098 — Account Manipulation | Severs delegated admin relationships — GuardDuty, Security Hub, Config lose visibility |
| MITRE ATT&CK | T1531 — Account Access Removal | Cuts off security team's org-level access to the account mid-incident |
| MITRE ATT&CK | T1490 — Inhibit System Recovery | Removes Config remediation, backup policies, and service quota controls |
| OWASP Top 10:2025 | A01:2025 — Broken Access Control | Org egress bypasses every access control enforced at the org level |
| STRIDE | Elevation of Privilege | Leaving the org removes SCP restrictions — the account's effective permissions immediately expand |
