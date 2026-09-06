# ADR 001: Selection of Cilium for Zero-Trust Network Enforcement

**Status:** Accepted
**Date:** 2026-02-24
**Context:** AI workload isolation on the Fedora lab — enforcing network policy between containerized components (ML pipeline stages, model servers, Wazuh manager) where IP-based rules are insufficient because container IPs are not stable across restarts.

---

## Decision

Cilium with its eBPF data plane is the CNI for all container network policy enforcement in this environment.

---

## Rationale

### 1. Identity-Based Security (Zero Trust)

IP-based rules break when containers restart. Cilium assigns a cryptographic identity to every workload and enforces policy on that identity — not the IP. A model-serving container and a data-ingest container can run on the same host; policy prevents lateral movement between them even if IPs change.

- **MITRE:** T1210 (Exploitation of Remote Services) — lateral movement between workloads requires an explicit allow policy
- **STRIDE:** Tampering — a compromised container cannot reach adjacent workloads without a policy grant

### 2. eBPF Performance and Kernel-Level Enforcement

Cilium replaces iptables with eBPF programs loaded directly into the kernel. This matters for AI workloads where inference throughput is latency-sensitive — policy enforcement does not add userspace overhead.

Transparent WireGuard encryption between nodes is available at the same layer, requiring no sidecar.

### 3. L7 Visibility via Hubble

Hubble surfaces HTTP, gRPC, and DNS traffic per workload identity — not just L3 byte counts. For an ML pipeline, this means visibility into which component is calling the model API, with what frequency, and whether any unexpected consumers have appeared.

- **MITRE:** T1048 (Exfiltration Over Alternative Protocol) — Hubble detects unexpected outbound flows from a model-serving container
- **NIST 800-53:** AU-12 (Audit Record Generation)

### 4. Global Default Deny

The baseline policy (`global_default_deny.yaml`) denies all ingress and egress by default. Every communication path is an explicit allow — the minimum required for the workload to function.

- **NIST 800-53:** SC-7 (Boundary Protection), AC-4 (Information Flow)
- **OWASP Top 10:2025:** A01 (Broken Access Control)

---

## Trade-offs

| Factor | Detail |
|---|---|
| Kernel requirement | Linux 5.10+ — Fedora 43 (kernel 6.x) meets this comfortably |
| Complexity | Policy debugging requires `hubble observe` familiarity — steeper than iptables |
| Scope | This ADR covers the Fedora lab environment. Production would require per-environment policy review. |

---

## Compliance Mapping

| Control | Mapping |
|---|---|
| NIST 800-53 SC-7 | Boundary Protection — default deny enforced at network layer |
| NIST 800-53 SC-8 | Transmission Integrity — WireGuard encryption available |
| NIST 800-53 AC-4 | Information Flow — explicit allow-list per workload identity |
| MITRE T1210 | Exploitation of Remote Services — lateral movement blocked |
| MITRE T1048 | Exfiltration — Hubble detects unexpected egress flows |
