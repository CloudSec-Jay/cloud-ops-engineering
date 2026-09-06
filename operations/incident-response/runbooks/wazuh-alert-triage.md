# Runbook: Wazuh Alert Triage

A runbook is operational steps for a specific tool or process. This covers how to triage a Wazuh alert from first look to escalation decision. The playbooks in `playbooks/` cover what to do after you decide it's real.

---

## Step 1 — Open the Alert

In Wazuh dashboard: **Security Events → filter by rule level ≥ 9**

Key fields to read first:
| Field | What it tells you |
|---|---|
| `rule.id` | Which rule fired |
| `rule.description` | What behavior was detected |
| `rule.mitre.technique` | ATT&CK technique |
| `agent.name` | Which host |
| `data.srcip` | Source IP (if network event) |
| `full_log` | Raw log that triggered the rule |

---

## Step 2 — Read the Full Log

Don't triage from the description alone. Open `full_log` and read the raw event.

Common mistakes:
- Rule says "brute force" but full_log shows a service account doing automated logins → likely false positive
- Rule says "file modified" but full_log shows `/tmp/` → low priority vs `/etc/passwd`

---

## Step 3 — Check for Context (Last 15 Minutes on Same Host)

```
Filters:
  agent.name: <hostname>
  timestamp: last 15 minutes
```

- Is this an isolated event or part of a sequence?
- Did a login precede a privilege escalation?
- Did a file write follow a network connection?

A single alert in isolation is different from the same alert preceded by brute force + lateral movement.

---

## Step 4 — Escalation Decision

| Condition | Action |
|---|---|
| Single low-level event, no context, known service account | Document, close as FP |
| Repeated events on same host in short window | Escalate — open playbook |
| Any rule ≥ 12 (High) | Escalate immediately |
| FIM alert on `/etc/passwd`, `/etc/shadow`, `/etc/sudoers` | Escalate immediately |
| Reverse shell pattern, setuid execution by unexpected user | Escalate immediately |

---

## Step 5 — Document Before Closing

Even false positives get a one-liner note:
```
2026-03-24 | rule 100201 | agent: web-01 | FP: Jenkins service account automated login. Expected behavior.
```

If it's a true positive — open the relevant playbook.

---

## Rule Reference

| Rule ID Range | Category |
|---|---|
| 100001–100099 | Authentication / brute force |
| 100100–100199 | Privilege escalation |
| 100200–100299 | File integrity |
| 100300–100399 | Network / reverse shell |
