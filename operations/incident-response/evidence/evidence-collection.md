# Evidence Collection

Evidence collected during an incident. Each file in this directory corresponds to one incident.

## Naming Convention

```
IR-YYYY-###-<hostname>-<artifact-type>.txt
```

Examples:
```
IR-2026-001-web01-ps-output.txt
IR-2026-001-web01-netstat.txt
IR-2026-001-web01-auth-log.txt
```

---

## Collection Commands (copy-paste during IR)

```bash
INCIDENT="IR-$(date +%Y)-001"
HOST=$(hostname)
TS=$(date +%Y%m%d%H%M)

# Running processes
ps auxf > /tmp/${INCIDENT}-${HOST}-ps-${TS}.txt

# Network connections
ss -tlnp > /tmp/${INCIDENT}-${HOST}-netstat-${TS}.txt

# Logged-in users
who > /tmp/${INCIDENT}-${HOST}-who-${TS}.txt
last -F | head -50 > /tmp/${INCIDENT}-${HOST}-last-${TS}.txt

# Auth log (last 500 lines)
tail -500 /var/log/auth.log > /tmp/${INCIDENT}-${HOST}-auth-${TS}.txt

# Auditd events (last hour)
ausearch --start recent > /tmp/${INCIDENT}-${HOST}-audit-${TS}.txt

# SUID binaries
find / -xdev -perm -4000 -type f 2>/dev/null > /tmp/${INCIDENT}-${HOST}-suid-${TS}.txt

# Cron jobs
crontab -l 2>/dev/null > /tmp/${INCIDENT}-${HOST}-cron-${TS}.txt

# Open files
lsof > /tmp/${INCIDENT}-${HOST}-lsof-${TS}.txt
```

---

## Chain of Custody

| File | Collected By | Date/Time | SHA256 | Notes |
|---|---|---|---|---|
| | | | | |
