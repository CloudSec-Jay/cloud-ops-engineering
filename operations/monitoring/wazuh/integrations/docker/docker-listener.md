# Wazuh Docker Listener Integration

**Platform:** Fedora workstation (Wazuh agent)
**Wazuh rules:** 87900–87999 (built-in Docker ruleset)
**Status:** Active

---

## What It Does

The Wazuh docker-listener wodle connects to the Docker socket and streams container lifecycle events to the Wazuh manager in real time.

| Event | Rule | What it catches |
|-------|------|----------------|
| Container start/stop | 87901 | Unexpected container launches |
| `exec_create` / `exec_start` | 87903 | Someone exec'd into a running container (T1609) |
| Container launched privileged | 87932 | `--privileged` or `--cap-add` abuse (T1610) |
| Network connect/disconnect | 87929 | Container network changes |
| Image pull | 87910 | Unexpected image pulls — supply chain signal |

---

## Prerequisites

```bash
# Python docker library (system Python)
sudo pip3 install docker==7.1.0 urllib3==1.26.20 requests==2.32.2 --break-system-packages

# wazuh user needs docker socket access
sudo usermod -aG docker wazuh
sudo systemctl stop wazuh-agent && sudo systemctl start wazuh-agent
```

---

## Agent Config

In `/var/ossec/etc/ossec.conf`:

```xml
<wodle name="docker-listener">
  <interval>10m</interval>
  <attempts>5</attempts>
  <run_on_start>yes</run_on_start>
  <disabled>no</disabled>
</wodle>
```

---

## Verify

```bash
# Confirm socket access
sudo -u wazuh python3 -c "import docker; c = docker.from_env(); print(c.ping())"

# Trigger an event
docker stop <container> && docker start <container>

# Check manager alerts
docker exec single-node-wazuh.manager-1 grep "docker" /var/ossec/logs/alerts/alerts.json | tail -10
```

---

## Framework Mapping

| Technique | ID | What the listener catches |
|-----------|----|--------------------------|
| Deploy Container | T1610 | Privileged container launch |
| Container Administration Command | T1609 | exec into running container |
| Supply Chain Compromise | T1195 | Unexpected image pull |
