# Wazuh Podman Quadlets

System-level Podman Quadlet definitions for running a single-node Wazuh manager, indexer, and dashboard under systemd.

## Status and requirements

- Designed for a Linux host with systemd and Podman Quadlet support
- Current unit files reference Wazuh `4.9.0`; review compatibility and upgrade guidance before deployment
- Requires root access to `/etc/containers/systemd/` and `/etc/wazuh/`
- Requires generated certificates and a populated `/etc/wazuh/secrets.env`

## Layout

- `*.container`, `*.network`, and `*.volume`: Quadlet units
- `config/`: indexer and dashboard configuration templates
- `config.yml` and `wazuh_certs_tool.sh`: certificate-generation inputs and helper
- `env.template`: required environment-variable template
- `deploy_wazuh.sh`: privileged installation and startup helper
- `nuke_wazuh.sh`: destructive teardown helper

## Review before deployment

```bash
bash -n containers/quadlets/wazuh/deploy_wazuh.sh
bash -n containers/quadlets/wazuh/nuke_wazuh.sh
podman quadlet --dryrun containers/quadlets/wazuh/wazuh_manager.container
```

Confirm volume-unit coverage, SELinux labels, bind addresses, certificate names, secrets, and service dependencies on the target host. The dashboard is published on host port 443; manager enrollment ports are also externally bound. The indexer and manager API are loopback-only in the current units.

## Destructive teardown

`nuke_wazuh.sh` stops services, force-removes Wazuh containers and volumes, deletes matching Quadlet files, and recursively removes `/etc/wazuh/`. It destroys indexed alerts and local configuration. Run it only after verifying the host and taking any required backups.
