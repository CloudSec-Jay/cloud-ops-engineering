# Kubernetes Platform

This directory demonstrates a small Kubernetes networking and identity baseline.

## Contents

- [`cilium/ADR_001_Cilium_eBPF.md`](cilium/ADR_001_Cilium_eBPF.md): rationale and tradeoffs for Cilium
- [`cilium/global_default_deny.yaml`](cilium/global_default_deny.yaml): Cilium default-deny example
- [`manifests/deny-all-network-policy.yaml`](manifests/deny-all-network-policy.yaml): standard Kubernetes ingress/egress deny policy
- [`helm/cilium-values.md`](helm/cilium-values.md): Cilium installation and Hubble notes
- [`security/service-accounts.md`](security/service-accounts.md): least-privilege RBAC and workload identity pattern
- [`scripts/minikube_setup.sh`](scripts/minikube_setup.sh): destructive local-cluster recreation script

## Local validation

```bash
kubectl apply --dry-run=client -f platform/kubernetes/manifests/deny-all-network-policy.yaml
kubectl apply --dry-run=client -f platform/kubernetes/cilium/global_default_deny.yaml
bash -n platform/kubernetes/scripts/minikube_setup.sh
```

The Minikube script deletes the selected profile before recreating it with the `kvm2` driver. Confirm the profile name, available memory, required CLIs, and recovery expectations before running it.
