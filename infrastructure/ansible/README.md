# Ansible

Ansible assets for Linux configuration, hardening, and maintenance.

## Playbooks

| Playbook | Target | Purpose | Risk |
|---|---|---|---|
| `cis_rhel9_hardening.yml` | `rhel_servers` inventory group | CIS-oriented RHEL 9 controls and audit rules | Can change authentication, auditing, and host policy |
| `fedora-cis-hardening.yml` | Localhost | Fedora workstation hardening | Broad privileged host changes |
| `gap_harding.yml` | Localhost | Additional Fedora control gaps | Changes PAM, mounts, packages, boot parameters, and logging |
| `install_mysql.yml` | Localhost | Legacy standalone MySQL container example | Uses a mutable MySQL tag, publishes port 3306 on all interfaces, requires an untracked playbook-local vars file, and must not run alongside the capacity Compose stack |
| `system_cleanup.yml` | Localhost | Cache, container, and log cleanup | Destructive cleanup and root scheduling |

## Setup and validation

```bash
ansible-galaxy collection install -r infrastructure/ansible/collections/requirements.yml
cp infrastructure/ansible/inventory/inventory.example.ini infrastructure/ansible/inventory/inventory.ini
ansible-playbook --syntax-check infrastructure/ansible/playbooks/PLAYBOOK.yml
ansible-lint --config-file infrastructure/ansible/.ansible-lint infrastructure/ansible/
```

Review `--check --diff` output where the modules support check mode. Use a disposable or recoverable test host first, especially for PAM, bootloader, filesystem-mount, audit, firewall, and cleanup tasks.

The canonical local EC2 capacity stack is [`../../operations/capacity-analytics/`](../../operations/capacity-analytics/README.md). Its MySQL service is owned by Docker Compose. The legacy `install_mysql.yml` playbook remains for review and learning but is not currently a reproducible deployment because `playbooks/vars/secrets.yml` is intentionally absent and no example file is provided.
