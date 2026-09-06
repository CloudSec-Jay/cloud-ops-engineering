#!/usr/bin/env bash
set -euo pipefail

#single-node minikube set up w/ cilum
PROFILE="${1:-tutorial-cilium}"
MEMORY="${2:-8192}"
CILIUM_VERSION="1.19.0"

echo "[*] Deleting existing profile: $PROFILE"
minikube delete -p "$PROFILE" 2>/dev/null || true

echo "[*] Starting minikube"
minikube start \
  --driver=kvm2 \
  --memory="$MEMORY" \
  --disk-size=30g \
  --network-plugin=cni \
  --cni=false \
  -p "$PROFILE"

echo "[*] Adding Cilium Helm repo"
helm repo add cilium https://helm.cilium.io/ 2>/dev/null || true
helm repo update

#cilium requires a replica to fix error set=1
echo "[*] Installing Cilium v${CILIUM_VERSION}"
helm install cilium cilium/cilium \
  --version "$CILIUM_VERSION" \
  --namespace kube-system \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set operator.replicas=1

#backup to operator error
echo "[*] Scaling cilium-operator to 1 replica (single node)"
kubectl scale deployment cilium-operator -n kube-system --replicas=1

echo "[*] Waiting for Cilium"
cilium status --wait

echo "[*] Done — profile: $PROFILE"
echo "[*] Run: cilium status"
echo "[*] Run: kubectl get pods -n kube-system"
echo "[*] Run: cilium hubble ui"
