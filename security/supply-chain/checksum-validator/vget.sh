#!/usr/bin/env bash
# vget — Secure Download & Verify Helper
#
# Downloads a file via curl and verifies its SHA256 (or other) checksum
# using checksum.py before trusting it. Deletes the file on mismatch.
#
# Threat: MITRE T1195.002 — Supply Chain Compromise (tampered binary)
#
# Usage:
#   source vget.sh
#   vget <URL> <EXPECTED_HASH> [ALGO (default: sha256)]
#
# Example:
#   vget https://github.com/gitleaks/gitleaks/releases/download/v8.30.0/gitleaks_8.30.0_linux_x64.tar.gz \
#       79a3ab579b53f71efd634f3aaf7e04a0fa0cf206b7ed434638d1547a2470a66e
#
# Setup: add to ~/.bashrc:
#   source /path/to/cloud-ops-engineering/security/supply-chain/checksum-validator/vget.sh
#   export CHECKSUM_PY=/path/to/cloud-ops-engineering/security/supply-chain/checksum-validator/checksum.py

vget() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: vget <URL> <EXPECTED_HASH> [ALGO (default: sha256)]"
        return 1
    fi

    local url="$1"
    local expected_hash="$2"
    local algo="${3:-sha256}"
    local filename="${url##*/}"

    # Use CHECKSUM_PY env var if set, else look next to this script
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local checksum_py="${CHECKSUM_PY:-${script_dir}/checksum.py}"

    if [ ! -f "$checksum_py" ]; then
        echo "❌ Error: checksum.py not found at '$checksum_py'"
        echo "   Set CHECKSUM_PY=/path/to/checksum.py or source from the repo directory."
        return 1
    fi

    echo "📥 Downloading $filename..."
    curl -LO "$url"

    if [ $? -ne 0 ]; then
        echo "❌ Error: Download failed."
        return 1
    fi

    echo "🔍 Verifying checksum..."
    python3 "$checksum_py" -f "$filename" -c "$expected_hash" -a "$algo"

    if [ $? -ne 0 ]; then
        echo "⚠️  SECURITY ALERT: Checksum mismatch! Deleting untrusted file: $filename"
        rm -f "$filename"
        return 1
    else
        echo "✅ File verified and ready for use."
    fi
}
