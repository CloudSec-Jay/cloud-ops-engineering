# SCP: Deny Public S3 Access Block Modification

**File:** `deny_public_s3.json`
**Scope:** AWS Organization — applies to all member accounts
**Type:** Service Control Policy (SCP)

---

## What This Does

Prevents any IAM principal in any member account from disabling S3 Block Public Access settings at either the bucket or account level. Both the `PutBucketPublicAccessBlock` and `PutAccountPublicAccessBlock` API calls are denied org-wide. The `SecurityAdmin` role is exempted to allow legitimate public access configuration (e.g. static website hosting) when explicitly authorized.

---

## Line-by-Line Breakdown

```json
"Action": [
    "s3:PutAccountPublicAccessBlock",
    "s3:PutBucketPublicAccessBlock"
]
```
Two actions, not one. `PutBucketPublicAccessBlock` controls the four Block Public Access flags at the individual bucket level. `PutAccountPublicAccessBlock` controls the same four flags at the account level — which applies to all buckets in that account. Both must be denied because an attacker or misconfigured role could bypass bucket-level controls by disabling at the account level first.

Note: There is no separate `DeletePublicAccessBlock` IAM action. AWS requires the same `Put` permission for both setting and removing the configuration. Denying `Put` covers both operations.

---

```json
"Resource": "*"
```
Required field — a Statement without `Resource` is invalid. For SCPs, resource-level scoping is not supported the same way as IAM policies. `*` is the correct and only valid value here.

---

```json
"Condition": {
    "StringNotLike": {
        "aws:PrincipalArn": "arn:aws:iam::*:role/SecurityAdmin"
    }
}
```

**`StringNotLike`** — fires the Deny for every principal whose ARN does NOT match the pattern. This is the inverse of `deny_root_action.json` which uses `StringLike` to target a specific principal. Here we use `StringNotLike` to exempt one principal and deny everyone else.

**`aws:PrincipalArn`** — global condition key evaluated at request time. Contains the full ARN of the calling identity — IAM user, role, or federated principal.

**`arn:aws:iam::*:role/SecurityAdmin`** — the `*` in the account ID position matches any 12-digit account ID across the entire organization. This means the `SecurityAdmin` role in any member account is exempted, not just one specific account. Scope this to a specific account ID if tighter control is needed.

---

## Real-World Breach — Capital One 2019

In July 2019, a misconfigured WAF on an EC2 instance allowed a former AWS employee to exploit an SSRF vulnerability and query the IMDSv1 metadata service. This returned temporary credentials for an overly permissive IAM role. The attacker used those credentials to list and download over 100 million customer records from S3 buckets — including names, addresses, credit scores, and Social Security numbers.

The S3 buckets were not publicly accessible in this case, but the breach illustrated the full attack chain that public bucket misconfigurations make even easier:

1. Attacker gains initial foothold (SSRF, phishing, leaked key)
2. Discovers S3 buckets via `s3:ListBuckets` or public enumeration (T1619)
3. Accesses data from exposed or misconfigured bucket (T1530)
4. Exfiltrates 100M+ records before detection

**What this SCP changes:**

If Block Public Access is enforced org-wide, step 3 is eliminated for any bucket where a developer accidentally or intentionally disabled the setting. The SCP makes that misconfiguration impossible without the `SecurityAdmin` role.

**Sources:**
- [AWS — Capital One Data Breach (Senate testimony)](https://www.judiciary.senate.gov/imo/media/doc/Payne%20Testimony.pdf)
- [DOJ — United States v. Paige Thompson](https://www.justice.gov/usao-wdwa/pr/former-seattle-tech-worker-convicted-charges-related-2019-capital-one-data-breach)

---

## Framework Mapping

| Framework | Control | Rationale |
|-----------|---------|-----------|
| MITRE ATT&CK | T1530 — Data from Cloud Storage | Primary mitigation — prevents public bucket exposure that enables direct data collection |
| MITRE ATT&CK | T1619 — Cloud Storage Object Discovery | Blocks enumeration — no public bucket means nothing to discover or list |
| MITRE ATT&CK | T1190 — Exploit Public-Facing Application | Public S3 buckets are frequently used as initial access or pivot points in web app attacks |
| OWASP Top 10:2025 | A01:2025 — Broken Access Control | Public S3 misconfiguration is one of the most common broken access control findings in cloud environments |
| STRIDE | Information Disclosure | Public bucket exposure directly enables unauthorized access to stored data at scale |
