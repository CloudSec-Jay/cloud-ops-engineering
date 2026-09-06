#!/usr/bin/env bash
# deploy-wazuh.sh — install and start Wazuh quadlets
# Run as root: sudo bash deploy-wazuh.sh
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR=/etc/containers/systemd
CERTS_DIR=/etc/wazuh/certs
CONFIG_DIR=/etc/wazuh/config
SECRETS_FILE=/etc/wazuh/secrets.env
WAZUH_YML=/etc/wazuh/wazuh.yml

if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: run as root (sudo bash deploy-wazuh.sh)" >&2
  exit 1
fi

# ── 1. Verify certs ─────────────────────────────────────────────────────────
echo "[1/6] Verifying certs at $CERTS_DIR..."
REQUIRED_CERTS=(
  root-ca.pem admin.pem admin-key.pem
  wazuh.indexer.pem wazuh.indexer-key.pem
  wazuh.manager.pem wazuh.manager-key.pem
  wazuh.dashboard.pem wazuh.dashboard-key.pem
)
MISSING=0
for cert in "${REQUIRED_CERTS[@]}"; do
  [[ -f "$CERTS_DIR/$cert" ]] || { echo "  MISSING: $CERTS_DIR/$cert"; MISSING=1; }
done
[[ "$MISSING" -eq 0 ]] || { echo "Fix missing certs then re-run."; exit 1; }
# 444 = world-readable so non-root container users (opensearch, wazuh-dashboard) can read.
# Private keys remain on a root-owned path; SELinux z-label restricts container access.
chmod 444 "$CERTS_DIR"/*.pem
chown root:root "$CERTS_DIR"/*.pem
echo "  OK — all certs present and secured"

# ── 2. Install config files ──────────────────────────────────────────────────
echo "[2/6] Installing config files to $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"
cp "$SCRIPT_DIR/config/wazuh.indexer.yml"        "$CONFIG_DIR/"
cp "$SCRIPT_DIR/config/opensearch_dashboards.yml" "$CONFIG_DIR/"
cp "$SCRIPT_DIR/config/internal_users.yml"        "$CONFIG_DIR/"
chmod 644 "$CONFIG_DIR"/*.yml
echo "  OK"

# ── 3. Create secrets.env ────────────────────────────────────────────────────
echo "[3/6] Checking $SECRETS_FILE..."
# IMPORTANT: INDEXER_PASSWORD must match the bcrypt hash in internal_users.yml.
# Regenerate the bundled demo hashes before deployment with the Wazuh password
# tool, then store the matching values in $SECRETS_FILE.
if [[ ! -f "$SECRETS_FILE" ]]; then
  install -Dm600 "$SCRIPT_DIR/env.template" "$SECRETS_FILE"
  chown root:root "$SECRETS_FILE"
  echo "  Created $SECRETS_FILE from env.template."
  echo "  Replace all CHANGE_ME values and rerun this script."
  exit 1
fi
if grep -Eq '^(INDEXER_PASSWORD|API_PASSWORD|DASHBOARD_PASSWORD)=(|CHANGE_ME.*)$' "$SECRETS_FILE"; then
  echo "ERROR: replace all password placeholders in $SECRETS_FILE" >&2
  exit 1
fi
echo "  Using existing secrets file"

# ── 4. Generate wazuh.yml (dashboard API config) ─────────────────────────────
echo "[4/6] Generating $WAZUH_YML..."
API_PASS="$(grep ^API_PASSWORD "$SECRETS_FILE" | cut -d= -f2-)"
sed "s/WAZUH_API_PASSWORD/${API_PASS}/" "$SCRIPT_DIR/config/wazuh.yml.template" > "$WAZUH_YML"
# 644: entrypoint script (/wazuh_app_config.sh) writes to this file on startup
chmod 644 "$WAZUH_YML"
chown root:root "$WAZUH_YML"
echo "  OK"

# ── 5. Install quadlet files ─────────────────────────────────────────────────
echo "[5/6] Installing quadlet files to $QUADLET_DIR..."
cp "$SCRIPT_DIR"/wazuh-indexer.container \
   "$SCRIPT_DIR"/wazuh-manager.container \
   "$SCRIPT_DIR"/wazuh-dashboard.container \
   "$SCRIPT_DIR"/wazuh.network \
   "$QUADLET_DIR"/
for vf in "$SCRIPT_DIR"/*.volume; do
  [[ -f "$vf" ]] && cp "$vf" "$QUADLET_DIR/"
done

sysctl -w vm.max_map_count=262144 > /dev/null
echo "vm.max_map_count=262144" > /etc/sysctl.d/99-wazuh-indexer.conf
echo "  OK"

# ── 6. Reload and start in order ─────────────────────────────────────────────
echo "[6/6] Reloading systemd and restarting services..."
systemctl daemon-reload

systemctl stop wazuh-dashboard wazuh-manager wazuh-indexer 2>/dev/null || true
sleep 3

# Wipe the indexer data volume if it was written by a newer OpenSearch version.
# Lucene codec is NOT backwards-compatible — 4.9.0 (OpenSearch 2.13) cannot read
# data written by 4.14.2 (OpenSearch 2.19, Lucene 9.12).
if podman volume exists systemd-wazuh-indexer-data 2>/dev/null; then
  if [[ "${ALLOW_WAZUH_DATA_RESET:-0}" == "1" ]]; then
    echo "  Removing indexer data volume because ALLOW_WAZUH_DATA_RESET=1..."
    podman volume rm systemd-wazuh-indexer-data
  else
    echo "  Preserving existing indexer data volume."
    echo "  Set ALLOW_WAZUH_DATA_RESET=1 only for an intentional reset."
  fi
fi

echo "  Starting wazuh-indexer (allow 60s for OpenSearch security init)..."
systemctl start wazuh-indexer
sleep 60

echo "  Starting wazuh-manager..."
systemctl start wazuh-manager
sleep 20

echo "  Starting wazuh-dashboard..."
systemctl start wazuh-dashboard
sleep 5

echo ""
echo "═══════════════════════════════════════════════════"
echo " Service Status"
echo "═══════════════════════════════════════════════════"
systemctl status wazuh-indexer wazuh-manager wazuh-dashboard --no-pager | grep -E "●|Active:"

HOST_IP="$(hostname -I | awk '{print $1}')"
echo ""
echo "  Dashboard: https://${HOST_IP}"
echo "  Username:  admin"
echo "  Password:  $(grep ^INDEXER_PASSWORD "$SECRETS_FILE" | cut -d= -f2-)"
echo ""
echo "  Tail logs:  journalctl -u wazuh-indexer -f"
