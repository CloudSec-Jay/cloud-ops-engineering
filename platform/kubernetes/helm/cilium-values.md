# Cilium Helm Values — Notes

Helm values for Cilium CNI. The full install is in `kubernetes/notes/minikube_setup.sh`.
This file documents the key flags and why they're set.

---

## Key Values

```yaml
# Disable kube-proxy replacement — avoids bootstrap deadlock on single-node
kubeProxyReplacement: false

# Hubble observability
hubble:
  relay:
    enabled: true
  ui:
    enabled: true

# Single replica — default 2 but second can't schedule on single-node cluster
operator:
  replicas: 1

# SPIFFE/SPIRE workload identity (target state)
authentication:
  mutual:
    spire:
      enabled: true
```

---

## Why Not Full kube-proxy Replacement

Full replacement (`kubeProxyReplacement: strict`) routes all service traffic through Cilium eBPF instead of iptables. Requires disabling kube-proxy at bootstrap. On minikube, this causes an API server bootstrap deadlock — Cilium needs the API server to start, API server needs networking, kube-proxy isn't there yet.

For production clusters bootstrapped with kubeadm: pass `--skip-phases=addon/kube-proxy` and set `kubeProxyReplacement: strict`.

---

## Hubble Flow Inspection

```bash
# Watch live flows
cilium hubble observe --follow

# Watch flows for a specific namespace
cilium hubble observe --namespace application --follow

# Watch dropped packets only
cilium hubble observe --verdict DROPPED --follow
```

Hubble shows: source pod → destination pod, policy verdict (ALLOW/DROP), L7 protocol details.
