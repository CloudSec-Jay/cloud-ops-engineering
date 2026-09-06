#!/usr/bin/env bash
# nuke-wazuh.sh — wipe every trace of Wazuh: services, containers, volumes, network, config
# Run as root: sudo bash nuke-wazuh.sh
set -euo pipefail

[[ "$EUID" -ne 0 ]] && { echo "Run as root"; exit 1; }

echo "=== Stopping services ==="
systemctl stop wazuh-dashboard wazuh-manager wazuh-indexer wazuh-network 2>/dev/null || true
systemctl disable wazuh-dashboard wazuh-manager wazuh-indexer 2>/dev/null || true

echo "=== Killing any leftover containers ==="
podman rm -f wazuh.dashboard wazuh.manager wazuh.indexer 2>/dev/null || true

echo "=== Removing all wazuh volumes ==="
podman volume ls --format "{{.Name}}" | grep -i wazuh | xargs -r podman volume rm -f
# Also catch the systemd-prefixed ones
podman volume ls --format "{{.Name}}" | grep "^systemd-wazuh" | xargs -r podman volume rm -f
podman volume ls --format "{{.Name}}" | grep "^systemd-wazuh\|wazuh-" | xargs -r podman volume rm -f

echo "=== Removing wazuh network ==="
podman network rm systemd-wazuh 2>/dev/null || true

echo "=== Removing quadlet files from /etc/containers/systemd/ ==="
rm -f /etc/containers/systemd/wazuh-*.container
rm -f /etc/containers/systemd/wazuh-*.volume
rm -f /etc/containers/systemd/wazuh.network

echo "=== Removing /etc/wazuh/ ==="
rm -rf /etc/wazuh/

echo "=== Reloading systemd ==="
systemctl daemon-reload
systemctl reset-failed 2>/dev/null || true

echo ""
echo "Done. All Wazuh data, volumes, config, and quadlet units removed."
podman volume ls | grep -i wazuh || echo "No wazuh volumes remaining."
podman ps -a | grep -i wazuh || echo "No wazuh containers remaining."
