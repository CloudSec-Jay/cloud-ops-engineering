# 03 — SLOs and Error Budgets

## Outcome

The demo service from brief 02 has written SLOs, Prometheus recording rules for its SLIs, multi-window burn-rate alerts, and an error-budget dashboard. The canary analysis in 02 judges releases against the same SLI definitions.

## What it proves

- You measure reliability as users experience it (SLIs), not just whether a box is up.
- You alert on **budget burn**, which pages early for fast outages and stays quiet for noise.
- Release safety and reliability measurement use one definition of "healthy."

This is reliability engineering, not security detection, which belongs to SecOps.

## Where it lives

`operations/slo/` (SLO doc, PrometheusRule, rule tests), delivered by the `slo` Argo Application from brief 02

## Requirements

### SLO document (`operations/slo/README.md`)

- [ ] Service, owner, and user journey ("GET / on podinfo")
- [ ] **Availability SLI:** non-5xx responses ÷ all responses, from `http_requests_total{status}`
- [ ] **Latency SLI:** requests ≤ 250ms ÷ all requests, from `http_request_duration_seconds_bucket{le="0.25"}` ÷ `_count`
- [ ] Targets and window, for example 99.5% availability and 99% latency over 30 days rolling
- [ ] Error budget in plain numbers (99.5% over 30 days ≈ 3.6 hours of full outage)
- [ ] Error-budget policy: what changes when the budget runs out (freeze feature releases, reliability work first)

### Recording rules

- [ ] Error ratio recorded over the windows the alerts need: 5m, 30m, 1h, 2h, 6h, 1d, 3d, and 30d
- [ ] Use a consistent naming scheme, for example `slo:sli_error:ratio_rate5m`
- [ ] Budget remaining: `1 - (30d error ratio / (1 - target))`

### Burn-rate alerts (SRE Workbook multi-window, multi-burn-rate)

| Severity | Long window | Short window | Burn rate | Budget spent |
|---|---|---|---|---|
| page | 1h | 5m | 14.4× | 2% in 1h |
| page | 6h | 30m | 6× | 5% in 6h |
| ticket | 1d | 2h | 3× | 10% in 1d |
| ticket | 3d | 6h | 1× | 10% in 3d |

- [ ] Both windows must exceed the threshold, so the alert resets quickly after recovery
- [ ] Per this repo's AGENTS rules, each alert documents: behavior, log or metric source, severity rationale, likely false positives (low traffic, deploy blips), and the response procedure
- [ ] Ship as a `PrometheusRule` (the operator CRD) so Argo CD delivers it

### Tests (no cluster needed)

- [ ] `promtool test rules` unit tests with synthetic series: a fast burn fires the page alert, a slow burn fires only the ticket alert, and healthy traffic fires nothing
- [ ] promtool can't read the CRD wrapper directly. In CI, extract `.spec` with `yq` to a temp file, then run `promtool check rules` and `promtool test rules`. The `prom/prometheus:v3.13.3` image includes promtool.

### Dashboard

- [ ] Grafana dashboard JSON provisioned through Git (a ConfigMap with the `grafana_dashboard` label, which kube-prometheus-stack's sidecar loads): SLI vs. target, budget remaining, burn rate per window, and rollout annotations

## Done when (evidence)

- [ ] promtool tests pass in CI
- [ ] Dashboard screenshot during the brief-02 bad-release demo, showing the burn-rate spike and budget dip
- [ ] A burn-rate alert fired and resolved in Alertmanager (screenshot or log)
- [ ] The SLO doc states what the error-budget policy would have required after the demo

## Out of scope

Multi-service SLOs, SLO-as-code generators (Sloth, Pyrra), and paging integrations. Mention them as next steps in the README.
