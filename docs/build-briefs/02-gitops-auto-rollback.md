# 02 — GitOps Delivery with Automatic Rollback

## Outcome

Merging a PR is the only way to deploy. Argo CD syncs the cluster from Git, and Argo Rollouts releases each change as a canary. When the canary's error rate or latency breaks the threshold, the rollout aborts and traffic returns to the stable version with no human involved.

## What it proves

- Declarative, auditable delivery: Git history is the deployment history.
- Safe releases: progressive delivery with automated, metric-driven rollback.
- You can **demo** a failure on purpose and show the system catching it.

## Where it lives

`platform/gitops/` (bootstrap, Argo Applications, workload manifests)

## Stack (versions checked 2026-10-11)

| Component | Version |
|---|---|
| k3s (or kind for laptop testing) | current stable |
| Argo CD | v3.5.3, `manifests/install.yaml` from the tag |
| Argo Rollouts | v1.10.0, `install.yaml` release asset |
| kube-prometheus-stack (Helm) | 91.6.0 |
| Demo app: podinfo | `ghcr.io/stefanprodan/podinfo:6.15.0` |
| Load generator | `curlimages/curl:8.16.0` |

## Requirements

### Bootstrap

- [ ] A script that installs Argo CD and Rollouts from **pinned** URLs into an **explicitly named** kube context (refuse to run otherwise and confirm before applying), then applies a root Application
- [ ] Use server-side apply for Argo CD; its CRDs are too large for client-side apply
- [ ] Use the app-of-apps pattern: the root app watches `platform/gitops/apps/`, which holds one Application each for monitoring, the demo workload, and the SLO rules (brief 03)
- [ ] Automated sync with `prune` and `selfHeal`, so a manual `kubectl edit` gets reverted, which is itself a drift story

### Monitoring app

- [ ] kube-prometheus-stack with sync-wave `-1`, so the CRDs exist before workloads
- [ ] `serviceMonitorSelectorNilUsesHelmValues: false` and `ruleSelectorNilUsesHelmValues: false`. Without these, your ServiceMonitor and PrometheusRule are silently ignored.
- [ ] Retention of at least 30 days to cover the SLO window
- [ ] Grafana admin password from an existing Secret created outside Git
- [ ] Set `fullnameOverride` so the Prometheus Service name is predictable for the analysis provider address

### Demo workload: podinfo

- [ ] `Rollout` (not a Deployment) with about 5 replicas, a pod-security `restricted` namespace, resource requests and limits, read-only root filesystem, dropped capabilities, and seccomp `RuntimeDefault`
- [ ] **podinfo gotchas, checked against source at 6.15.0:**
  - The image runs as a *named* user (`USER app`), so `runAsNonRoot` alone fails admission. Set a numeric `runAsUser` and confirm the UID in the image (`podman run --rm --entrypoint id ghcr.io/stefanprodan/podinfo:6.15.0`).
  - Run with `--port-metrics=9797`. `--random-error` middleware wraps *every* route on the main port, including `/metrics` and `/healthz`. The metrics port has its own `/metrics` and `/healthz`, unaffected by the fault, so point probes and scraping there.
  - Metrics: `http_requests_total{status}` and `http_request_duration_seconds_bucket{method,path,status,le}` with default buckets, so `le="0.25"` exists.
  - Mount an `emptyDir` at `/data` if the root filesystem is read-only.
- [ ] One Service exposing `http` (9898) and `http-metrics` (9797). Without a mesh, Rollouts splits traffic by **replica count**; document that tradeoff.
- [ ] ServiceMonitor with `podTargetLabels: [rollouts-pod-template-hash]`, so each series carries `rollouts_pod_template_hash` and analysis can query the **canary pods only**
- [ ] Load generator Deployment that curls the Service continuously. No traffic means no metrics, and no metrics means the analysis can't decide.

### Canary and analysis

- [ ] Canary steps, for example `setWeight 20` → pause → `setWeight 50` → pause → full
- [ ] **Background analysis** from step 1, passing `canary-hash` via `valueFrom.podTemplateHashValue: Latest`
- [ ] AnalysisTemplate with a Prometheus provider and two metrics:
  - canary 5xx ratio ≤ 1%. The numerator is empty when there are zero errors, so wrap it in `or vector(0)`.
  - canary p95 latency ≤ 250ms (`histogram_quantile` over `sum by (le)`)
- [ ] **Fail closed.** No data (empty result) must count as an error, not a pass. Use `initialDelay` so the first scrape lands before evaluation starts.
- [ ] Keep the thresholds consistent with the SLI definitions in brief 03

### The "bad release" demo

- [ ] A documented one-line PR that flips podinfo to `--random-error=true` (about 1 in 3 requests fail)
- [ ] Merge it, and Argo CD syncs, the canary starts, analysis fails, the rollout aborts, and stable keeps serving
- [ ] Revert the PR to recover cleanly

## Done when (evidence)

- [ ] A good PR rolls out to 100% with successful analysis runs
- [ ] The bad-release PR is **rolled back automatically**. Capture `kubectl argo rollouts get rollout podinfo` output and the failed AnalysisRun.
- [ ] Grafana screenshot showing the canary error spike and recovery
- [ ] A manual `kubectl scale` reverted by self-heal
- [ ] Lint in CI: `kubeconform` or `kubectl --dry-run=server` against the manifests, plus `bash -n` and shellcheck on the bootstrap script

## Out of scope

Service mesh traffic routing, multi-cluster, and image promotion pipelines. Revisit these after the demo works.
