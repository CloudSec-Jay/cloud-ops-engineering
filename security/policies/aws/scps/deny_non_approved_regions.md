# SCP: Deny Non-Approved Regions

**File:** `deny_non_approved_regions.json`
**Scope:** AWS Organization — applies to all member accounts
**Type:** Service Control Policy (SCP)

---

## What This Does

Blocks any IAM principal in any member account from deploying or accessing AWS services in regions outside the four approved US regions (`us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`). Global services (IAM, STS, S3, Route53, CloudFront, Support, Organizations) are exempted because they do not target a specific region.

Attackers who compromise credentials immediately look for regions with no CloudWatch alarms, no GuardDuty coverage, and no Config rules. This SCP eliminates that option — if it's not a US region, the API call is denied before it reaches the service.

---

## Line-by-Line Breakdown

```json
"NotAction": [
    "iam:*",
    "sts:*",
    "s3:*",
    "route53:*",
    "cloudfront:*",
    "support:*",
    "organizations:*"
]
```

**`NotAction`** — the inverse of `Action`. Instead of listing what to block, this lists what to exempt. Everything not in this list is subject to the Deny. This is the correct pattern for region restriction because the goal is to block *all* regional services except the approved list.

Each exemption exists for a specific reason:

| Service | Why exempted |
|---------|-------------|
| `iam:*` | IAM is global — no region. Blocking it breaks all IAM operations org-wide |
| `sts:*` | STS token service is global — role assumptions and federation break without it |
| `s3:*` | S3 control plane is global even though buckets have regions |
| `route53:*` | Route53 is global — DNS resolution breaks without it |
| `cloudfront:*` | CloudFront distributions are global — CDN configuration breaks |
| `support:*` | AWS Support API is global — needed to open support cases |
| `organizations:*` | Organizations API is global — needed for SCP management itself |

Depending on your environment, additional global services may need exempting — see the **Global Services Reference** section below.

---

```json
"Resource": "*"
```

Required field. `*` is the only valid value in SCPs — resource-level scoping belongs in IAM policies, not SCPs.

---

```json
"Condition": {
    "StringNotEquals": {
        "aws:RequestedRegion": [
            "us-east-1",
            "us-east-2",
            "us-west-1",
            "us-west-2"
        ]
    }
}
```

**`StringNotEquals`** — fires the Deny when the requested region does NOT match any value in the list. Every API call targeting a non-US region is denied. Calls targeting the four approved regions pass through.

**`aws:RequestedRegion`** — global condition key that evaluates to the region an API call is targeting. Available on every AWS API call regardless of service.

**The four approved regions:**
- `us-east-1` — US East (N. Virginia) — primary AWS region, most services available
- `us-east-2` — US East (Ohio) — DR pair for us-east-1
- `us-west-1` — US West (N. California)
- `us-west-2` — US West (Oregon) — major secondary region

**GovCloud excluded by design** — `us-gov-east-1` and `us-gov-west-1` are a separate AWS partition requiring separate enrollment. Add only if the environment specifically operates in GovCloud.

---

## Why NotAction Instead of Action

This SCP could have been written with `"Action": "*"`. The problem is global services.

IAM, STS, Route53, and CloudFront do not send requests to a specific region. When AWS evaluates `aws:RequestedRegion` for these services, it returns an empty value — and `StringNotEquals` on an empty value can deny global service calls entirely, breaking the environment.

Using `NotAction` explicitly carves out global services from the condition evaluation. The Deny only applies to regional services — which is exactly the intent.

---

## Global Services Reference

The `NotAction` list in this SCP covers the most common global services. Depending on your environment, these may also need to be added:

| Service | Global? | Add if... |
|---------|---------|-----------|
| `waf:*` | Yes (WAF Classic) | Using WAF Classic (WAF v2 / `wafv2:*` is regional) |
| `shield:*` | Yes | Using Shield Advanced for DDoS protection |
| `globalaccelerator:*` | Yes | Using Global Accelerator for network routing |
| `budgets:*` | Yes | Using AWS Budgets for cost alerts |
| `ce:*` | Yes | Using Cost Explorer API programmatically |
| `account:*` | Yes | Managing account settings via API |
| `health:*` | Yes | Using AWS Health / Personal Health Dashboard API |
| `trustedadvisor:*` | Yes | Using Trusted Advisor API |

Test after attaching — if a legitimate workflow breaks, the missing global service exemption is the first place to look.

---

## What This SCP Does Not Cover

**GovCloud regions** — separate AWS partition, not covered. Requires separate org configuration.

**S3 bucket region enforcement** — `s3:*` is exempted globally. To restrict which regions S3 buckets can be created in, use an AWS Config rule checking bucket region, separate from this SCP.

**Services without `aws:RequestedRegion` support** — most services support this condition key. Verify for any newly launched services.

---

## Real-World Breaches

### T1535 — Unused/Unsupported Cloud Regions

**Story 1 — Crypto mining in obscure regions (TeamTNT, 2020)**
TeamTNT, after compromising AWS credentials, deployed crypto mining infrastructure in regions outside the victim's primary operating region. Victims with GuardDuty and CloudWatch only in `us-east-1` had no visibility into mining running in `ap-southeast-1` or `eu-north-1`. Billing anomalies — not security alerts — were how victims discovered the activity. This SCP eliminates the obscure-region option entirely.
- Source: [Trend Micro — TeamTNT Cloud Credential Harvesting](https://www.trendmicro.com/en_us/research/20/i/teamtnt-now-deploying-ddos-capable-irc-bot-tnt-miner.html)

**Story 2 — Attacker C2 in unmonitored region**
After gaining IAM credentials via a publicly exposed `.env` file, attackers spin up EC2 in regions where the victim has no VPC, no Security Groups, and no CloudWatch log groups. The instances are used as C2 nodes or proxies. The victim's security tooling has no baseline because there was never legitimate activity in that region.
- Source: [GitHub — aws-customer-security-incidents](https://github.com/ramimac/aws-customer-security-incidents)

**Story 3 — Data exfiltration staging in foreign region**
Attackers exfiltrating S3 data have staged the operation through EC2 in regions with higher bandwidth and lower monitoring coverage — copying data to `ap-east-1` first, then exfiltrating from there, bypassing egress monitoring configured only on the primary region. Restricting EC2 launch to approved regions closes this staging path.
- Source: [MITRE ATT&CK T1535 — Procedure Examples](https://attack.mitre.org/techniques/T1535/)

---

### T1578 — Modify Cloud Compute Infrastructure

**Story 1 — EC2 launch in unmonitored region for persistence**
Attackers launch EC2 in non-primary regions to establish persistence. The instances run outside the victim's AMI baseline, patch management, and FIM coverage. Because the region was never used legitimately, no alerts are configured for new launches there.
- Source: [MITRE ATT&CK T1578 — Procedure Examples](https://attack.mitre.org/techniques/T1578/)

**Story 2 — Lambda deployment for covert execution**
Attackers with `lambda:CreateFunction` permissions have deployed Lambda functions in unmonitored regions to execute code on a schedule — no persistent EC2 needed. Lambda in a region with no CloudWatch log retention produces logs that are never reviewed. The function exfiltrates data or maintains persistence indefinitely.

**Story 3 — VPC peering from attacker-controlled region**
In multi-account environments, attackers have created VPCs in obscure regions and attempted VPC peering back to the victim's primary VPC. Operating from outside the victim's monitoring scope, the peering request and lateral movement traffic avoided detection. Region restriction prevents creating VPC infrastructure in the first place.

---

## Defense-in-Depth Stack

| Control | What it prevents |
|---------|-----------------|
| This SCP | Blocks all regional service calls outside approved US regions |
| GuardDuty enabled in all regions | Detects threats even in regions you don't use — enable globally |
| AWS Config multi-region | Tracks resource creation across all regions |
| CloudTrail multi-region trail | Logs API calls in every region — evidence even for blocked attempts |
| Cost Anomaly Detection | Catches unexpected spend in any region as a secondary signal |

---

## Framework Mapping

| Framework | Control | Rationale |
|-----------|---------|-----------|
| MITRE ATT&CK | T1535 — Unused/Unsupported Cloud Regions | Primary mitigation — blocks attacker use of unmonitored regions for mining, C2, and staging |
| MITRE ATT&CK | T1578 — Modify Cloud Compute Infrastructure | Blocks EC2, Lambda, and VPC creation outside approved regions |
| OWASP Top 10:2025 | A05:2025 — Security Misconfiguration | Unmonitored regions are a configuration gap — no alarms, no baseline, no detection |
| STRIDE | Elevation of Privilege | Operating in an unmonitored region removes all detective controls, effectively granting unconstrained access |
