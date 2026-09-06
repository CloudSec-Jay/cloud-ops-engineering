# Playbook: Linux Host Compromise

**Trigger:** Wazuh alert — privilege escalation, unauthorized setuid execution, FIM alert on `/etc/passwd` or `/etc/sudoers`, brute force success, or reverse shell detected.

**Severity:** High
**Owner:** Security Engineer
**Last Updated:** 2026-03-24

---

## 1. Identify — What do you actually have?

Before doing anything, answer these four questions:

- What triggered the alert? (rule ID, technique, log source)
- What host? (hostname, IP, AWS instance ID)
- What user/process? (UID, PID, binary path)
- When did it start? (first event timestamp — not when you saw it)

```bash
# Pull the triggering events from Wazuh for this host
# Filter by hostname and time window around the alert

# On the host — who is currently logged in?
who
w
last | head -20

# Any unexpected processes?
ps aux --sort=-%cpu | head -20

# Unexpected listening services?
ss -tlnp
```

**Decision point:** Is this a false positive? If yes — document and close. If no — move to Contain.

---

## 2. Contain — Stop the bleeding

Goal: prevent lateral movement and further damage. Do not wipe the host yet — you need evidence.

**If host is EC2:**
```bash
# Isolate via security group — remove all inbound/outbound except your IR access
aws ec2 modify-instance-attribute \
  --instance-id <instance-id> \
  --groups <ir-isolation-sg-id>
```

**If host is on-prem or SSM-managed:**
- Block outbound at the host firewall
- Do NOT shut down — memory forensics may be needed

```bash
# Lock the compromised user account immediately
passwd -l <username>

# Kill active sessions for that user
pkill -KILL -u <username>
```

**Preserve before you change anything:**
```bash
# Snapshot running process list
ps auxf > /tmp/ir-ps-$(date +%Y%m%d%H%M).txt

# Snapshot network connections
ss -tlnp > /tmp/ir-netstat-$(date +%Y%m%d%H%M).txt

# Snapshot logged-in users
who > /tmp/ir-who-$(date +%Y%m%d%H%M).txt
```

---

## 3. Investigate — What happened?

Work backwards from the alert. Build a timeline.

**Authentication events:**
```bash
# Failed and successful logins
grep -i "failed\|accepted\|invalid" /var/log/auth.log | tail -100

# sudo usage
grep sudo /var/log/auth.log | tail -50

# Last logins
last -F | head -30
```

**File integrity:**
```bash
# Check AIDE integrity (if configured)
aide --check 2>/dev/null

# Wazuh FIM — look for changes to sensitive files
# In Wazuh UI: filter rule.groups = syscheck, agent = <hostname>

# Recently modified files (last 24h)
find / -xdev -newer /tmp/ir-ps-*.txt -not -path "/proc/*" \
  -not -path "/sys/*" -not -path "/run/*" 2>/dev/null | head -50
```

**Persistence mechanisms:**
```bash
# Cron jobs
crontab -l 2>/dev/null
ls -la /etc/cron* /var/spool/cron/crontabs/ 2>/dev/null

# New user accounts or UID 0 accounts
awk -F: '($3 == 0) {print}' /etc/passwd
awk -F: '($2 != "!" && $2 != "*") {print $1}' /etc/shadow

# SUID binaries — compare against known baseline
find / -xdev -perm -4000 -type f 2>/dev/null

# Systemd persistence
systemctl list-units --type=service --state=running | grep -v "\.service$"
ls -la /etc/systemd/system/ | grep -v "^total"
```

**Process and network activity:**
```bash
# Open files by suspicious process
lsof -p <pid>

# Check /proc for deleted binaries still running (common malware pattern)
ls -la /proc/*/exe 2>/dev/null | grep deleted

# Outbound connections
ss -tnp | grep ESTABLISHED
```

**Audit log review:**
```bash
# Privilege escalation events
ausearch -k privilege_escalation --start today

# Identity file changes
ausearch -k identity --start today

# Setuid execution
ausearch -k setuid_exec --start today
```

---

## 4. Eradicate — Remove the threat

Only after you understand the full scope.

```bash
# Remove unauthorized accounts
userdel -r <username>

# Remove malicious binaries (verify first with file + strings)
file /path/to/suspicious/binary
rm /path/to/suspicious/binary

# Remove persistence (cron, systemd unit, rc.local entries)
crontab -r -u <username>
systemctl disable --now <malicious-service>
rm /etc/systemd/system/<malicious-service>.service

# Rotate credentials
# - SSH keys: remove from authorized_keys
# - AWS IAM: rotate or delete access keys for any role on this host
# - Service accounts: rotate all secrets that were accessible from this host
```

---

## 5. Recover — Bring the host back

**If host is unrecoverable (rootkit suspected, kernel tampered):**
- Terminate the instance
- Redeploy from known-good AMI via Terraform
- Restore data from backup — do not copy files from the compromised host

**If host is recoverable:**
```bash
# Re-run CIS hardening playbook
ansible-playbook -i <host>, infrastructure/ansible/playbooks/cis_rhel9_hardening.yml

# Reinitialize AIDE baseline
aide --init
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Re-enable isolated security group
aws ec2 modify-instance-attribute \
  --instance-id <instance-id> \
  --groups <normal-sg-id>
```

---

## 6. Document — What do you know now?

Fill this out before closing the incident.

| Field | Value |
|---|---|
| Incident ID | IR-YYYY-### |
| Date detected | |
| Date contained | |
| Host | |
| Initial vector | |
| Techniques observed | |
| Data accessed | |
| Accounts compromised | |
| Persistence found | |
| Root cause | |
| Detection gap (if any) | |

**Was it detected by an existing Wazuh rule?** If no — write the rule before closing.
**Was the attacker able to move laterally?** If yes — scope expands, repeat from step 1 on affected hosts.

---

## MITRE Techniques — Common in Linux Host Compromise

| Technique | What to look for |
|---|---|
| T1110 Brute Force | Auth log failed attempts before success |
| T1548 Abuse Elevation Control | sudo/setuid execution in auditd |
| T1059 Command and Scripting | Unexpected shell spawned from web process |
| T1053 Scheduled Task/Job | New cron entries, systemd timers |
| T1070 Indicator Removal | Log files truncated or deleted |
| T1222 File Permissions Modification | chmod on sensitive files (Wazuh FIM) |
| T1003 OS Credential Dumping | Access to /etc/shadow, /proc/*/mem |
