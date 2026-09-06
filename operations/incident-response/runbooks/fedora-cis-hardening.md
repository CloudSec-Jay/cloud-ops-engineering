# CIS Hardening — Fedora Workstation

**Role:** `ansible-lockdown.RHEL9-CIS` — implements CIS Benchmark for RHEL 9, adapted for Fedora 43 workstation.
**Target:** localhost (workstation), not a fleet deployment.
**Benchmark:** CIS Red Hat Enterprise Linux 9 Benchmark v2.0.0

---

## What the Role Does

The ansible-lockdown RHEL9-CIS role implements every CIS benchmark control as an Ansible task. Controls are grouped into 7 sections:

| Section | Coverage |
|---------|----------|
| 1 | Filesystem, kernel modules, package management, SELinux, login banners |
| 2 | Unnecessary services removal |
| 3 | Network hardening, kernel parameters |
| 4 | Logging — auditd, rsyslog, journald |
| 5 | Access control — SSH, sudo, PAM, password policy |
| 6 | System maintenance — audit tools, file permissions |
| 7 | Local user accounts, file integrity |

Each task maps to a CIS control ID (e.g. `1.1.1.8`, `5.1.10`). Variables named `rhel9cis_rule_X_X_X: false` skip individual controls.

---

## How to Run

```bash
cd ~/GitRepos/cloud-ops-engineering/infrastructure/ansible

# Dry run — shows what would change without touching anything
ansible-playbook -i localhost, -c local playbooks/fedora-cis-hardening.yml --check --ask-become-pass

# Apply
ansible-playbook -i localhost, -c local playbooks/fedora-cis-hardening.yml --ask-become-pass
```

Reboot after applying — kernel parameters and immutable audit rules require it.

---

## What Was Applied

### Kernel Modules Disabled (Section 1)
| Module | Why blocked |
|--------|-------------|
| `usb-storage` | USB drive exfil prevention (T1052.001) |
| `cramfs`, `hfs`, `hfsplus`, `udf` | Unused filesystems — attack surface reduction |
| `freevxfs`, `jffs2` | Unused filesystems |

**Impact:** USB drives will not mount. Mac-formatted drives will not mount.

### Services Removed (Section 2)
| Service | Reason |
|---------|--------|
| CUPS / cups-filters | No printer — removed dependency chain |
| Avahi | Removed after CUPS dependency cleared |
| gnome-user-share | WebDAV file sharing — unused |
| httpd | Web server — unused on workstation |

### SSH Hardening (Section 5)
| Setting | Value | Effect |
|---------|-------|--------|
| `AllowUsers` | `jayadmin` | Only this user can SSH in |
| `MaxAuthTries` | `4` | 4 failed attempts ends the session |
| `LoginGraceTime` | `60s` | Slow logins may time out |
| `PermitRootLogin` | `no` | Root SSH disabled |
| `PermitEmptyPasswords` | `no` | Empty passwords blocked |
| `X11Forwarding` | `no` | GUI forwarding disabled |
| `AllowTcpForwarding` | `no` | SSH tunneling disabled (T1572) |
| `IgnoreRhosts` | `yes` | .rhosts auth disabled |
| `HostbasedAuthentication` | `no` | Host-based auth disabled |

**Possible misconfiguration:** If you SSH from a different user or machine not in `AllowUsers`, access will be denied. Edit `rhel9cis_sshd_config_allowusers` in the playbook to add users.

### sudo Hardening (Section 5)
- `use_pty` — sudo requires a TTY. Scripts calling sudo non-interactively may fail.
- Sudo log at `/var/log/sudo.log` — every sudo command logged.

**Possible misconfiguration:** Automation scripts using `sudo` without a TTY will break. Fix with `Defaults:scriptuser !requiretty` in sudoers for specific users.

### PAM / Authentication (Section 5)
- authselect profile: `cis_fedora_workstation`
- faillock enabled — repeated failed logins lock the account
- Password minimum length and complexity enforced on next change
- Password reuse limited

**Possible misconfiguration:** Too many failed sudo attempts can lock your account. Unlock with: `sudo faillock --user jayadmin --reset`

### Password Policy (Section 5)
| Setting | Value |
|---------|-------|
| Max days | 365 |
| Min days between changes | 7 |
| Warning days | 7 |
| Inactive lock | 30 days |

### Audit Rules (Section 6)
- sudoers changes collected in auditd
- Audit configuration set immutable — changing audit rules requires reboot
- auditd log retention policy set (no auto-delete)

**Possible misconfiguration:** To modify audit rules after apply, reboot first or the changes will be blocked.

### SELinux (Section 1)
- Mode: enforcing (confirmed, not changed)
- Policy: targeted

---

## Skipped Controls and Why

| Control | Reason skipped |
|---------|---------------|
| Separate partitions (`/var`, `/var/tmp`, `/var/log`, `/var/log/audit`) | Requires full reinstall — not applicable to existing workstation |
| `/tmp` noexec | Dev tooling (Ansible, Python) executes from `/tmp` |
| Bootloader password | Laptop has BIOS/firmware password |
| Root password (5.4.2.4) | Root kept locked — sudo provides full audit trail |
| AIDE (6.1.3) | Wazuh FIM provides realtime equivalent — scheduled batch scanner redundant |
| autrace (6.3.4.8–10) | Not installed — `auditd` + Wazuh covers equivalent monitoring |
| journal-remote (6.2.2.1.x) | Wazuh manager is the centralized log host |
| rsyslog remote host | Wazuh agent handles log forwarding |
| GDM removal | Desktop requires display manager |
| Bluetooth (3.1.3) | gnome-shell hard dependency on gnome-bluetooth — service disabled separately |
| dnsmasq (2.1.5) | Required by libvirt for KVM/QEMU virtual network DHCP |
| squashfs (1.1.1.6) | Required by Distrobox and Flatpak |
| SUID removal (7.1.13) | Distrobox and KVM require specific SUID binaries |
| Home dir ACL lockdown (7.2.8) | Breaks GNOME desktop session |
| Dot file permissions (7.2.9) | Breaks `.bashrc`, `.Xauthority`, shell configs |
| SSH DisableForwarding (5.1.10) | Python 3.13 regex bug in role — applied manually |

---

## Known Compatibility Issues

**Python 3.13 regex bug in role:**
The role uses `^(?i)` inline flag patterns which Python 3.13 rejects. Fixed by running `fix_py313_regex.py` across all task files. If the role is updated, re-run the fix script.

```bash
python3 ~/GitRepos/cloud-ops-engineering/scripts/ansible/fix_py313_regex.py
```

**Fedora OS detection:**
The role has no `Fedora.yml` vars file. Symlinked to `RedHat.yml`:
```bash
ln -s RedHat.yml .ansible/roles/ansible-lockdown.RHEL9-CIS/vars/Fedora.yml
```

---

## Post-Apply Checklist

- [ ] Reboot
- [ ] Login works
- [ ] `sudo systemctl status wazuh-agent` — agent running
- [ ] `distrobox list` and `distrobox enter <name>` — containers work
- [ ] SSH from another machine works
- [ ] `docker compose ps` from wazuh-docker — Wazuh stack still up
- [ ] Run Wazuh SCA scan — check new score

---

## Re-running After Changes

The playbook is idempotent — safe to rerun anytime. Re-run after OS updates to catch any config drift.
