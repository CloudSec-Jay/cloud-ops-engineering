# SCP: Require IMDSv2 on All EC2 Launches

**File:** `require-imdsv2.json`
**Scope:** AWS Organization — applies to all member accounts
**Type:** Service Control Policy (SCP)

---

## What This Does

Blocks any EC2 instance from launching unless it explicitly sets `HttpTokens=required` — enforcing Instance Metadata Service v2 (IMDSv2) across the entire organization. No EC2 can launch with IMDSv1 enabled, regardless of how it was provisioned.

---

## What Is IMDS?

Every EC2 instance has a built-in HTTP endpoint at:

```
http://169.254.169.254/latest/meta-data/
```

This is the Instance Metadata Service (IMDS). It runs on port 80, bound to a link-local address only reachable from inside the instance. Any process on the instance can query it to get:

- IAM role credentials (access key, secret key, session token)
- Instance ID, region, VPC ID, subnet
- User data (often contains bootstrap secrets)

This endpoint exists so applications can discover their environment without hardcoding values. The problem is that in v1, there is no authentication.

---

## IMDSv1 vs IMDSv2

### IMDSv1 — One step, no auth

```bash
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/my-role
```

Returns the IAM role credentials immediately. Any process that can reach that IP gets the keys. No token, no session, no verification.

### IMDSv2 — Two steps, session token required

```bash
# Step 1: Request a session token using a PUT (not GET)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Step 2: Use the token in subsequent requests
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/my-role
```

Without a valid session token, the metadata endpoint returns a 401. The token requires a PUT request with a custom header — something most SSRF vulnerabilities cannot replicate.

---

## The Attack IMDSv2 Prevents — SSRF to Credential Theft

**SSRF (Server-Side Request Forgery)** — MITRE T1552.005

An SSRF vulnerability tricks your web application into making HTTP requests on the attacker's behalf. From the network's perspective, the request comes from inside your instance — meaning 169.254.169.254 is reachable.

**Attack chain with IMDSv1:**

```
1. Attacker finds SSRF in web app
         ↓
2. Sends crafted request:
   GET /?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-role
         ↓
3. App fetches the URL internally, returns response to attacker
         ↓
4. Attacker receives:
   {
     "AccessKeyId": "ASIA...",
     "SecretAccessKey": "...",
     "Token": "..."
   }
         ↓
5. Attacker uses credentials from their own machine
   — now operating as your EC2's IAM role
```

**With IMDSv2:** Step 2 requires a PUT with a custom header first. Standard SSRF follows GET redirects — it cannot satisfy the PUT requirement. No token means no credentials.

---

## The Capital One Breach — 2019

In July 2019, a former AWS engineer exploited an SSRF vulnerability in Capital One's AWS WAF (Web Application Firewall) running on EC2.

**What happened:**

1. The WAF had an SSRF vulnerability in its configuration
2. The attacker used it to query the IMDS endpoint at `169.254.169.254`
3. The EC2 instance had an IAM role attached with excessive S3 permissions
4. The attacker retrieved the role's temporary credentials via IMDSv1 — no authentication required
5. Using those credentials, they listed and downloaded over 30 S3 buckets
6. **106 million customer records** were exposed — names, addresses, credit scores, SSNs

**The controls that would have stopped it:**

| Control | How it helps |
|---------|-------------|
| IMDSv2 (`http_tokens = required`) | SSRF cannot complete the PUT handshake — no credentials returned |
| `hop_limit = 1` | Even if token retrieved, response never escapes the instance network layer |
| Least privilege IAM role | Even with credentials, S3 access scoped to specific buckets only |
| This SCP | No EC2 in the org can launch without IMDSv2 — enforced at the API level |

Capital One was fined $80 million. The breach was preventable with controls that existed at the time.

**Sources:**
- [Krebs on Security — What We Can Learn from the Capital One Hack](https://krebsonsecurity.com/2019/08/what-we-can-learn-from-the-capital-one-hack/)
- [InsiderSecurity — How SSRF Exposed 100 Million Customer Records](https://insidersecurity.co/capitalone-data-breach-how-ssrf-vulnerability-exposed-100-million-customer-records/)
- [AppSec Engineer — AWS Shared Responsibility Model: Capital One Case Study](https://www.appsecengineer.com/blog/aws-shared-responsibility-model-capital-one-breach-case-study)

---

## The `hop_limit = 1` Connection

This SCP enforces IMDSv2 at the API level. Your Terraform module adds a second layer:

```hcl
metadata_options {
  http_tokens                 = "required"    # IMDSv2 enforced
  http_put_response_hop_limit = 1             # Response TTL = 1 hop
}
```

`hop_limit = 1` means the token response packet decrements its TTL immediately and dies. It never traverses a container bridge, proxy, or NAT layer. A containerized process inside the EC2 cannot reach IMDS even with IMDSv2 — the response never arrives.

**Two controls, two layers:**

```
IMDSv2         → requires PUT handshake     → blocks SSRF at protocol layer
hop_limit = 1  → kills response packet      → blocks container escape at network layer
This SCP       → blocks launch without both → enforcement guarantee at org layer
```

---

## Line-by-Line Breakdown

```json
"Action": "ec2:RunInstances"
```
Targets only the instance launch API. This doesn't affect running instances, stop/start operations, or anything else — only the moment a new EC2 is launched.

---

```json
"Resource": "*"
```
Applies to any instance type, in any region, in any account. Required field.

---

```json
"Condition": {
    "StringNotEquals": {
        "ec2:MetadataHttpTokens": "required"
    }
}
```

`ec2:MetadataHttpTokens` — an EC2-specific condition key that reads the `HttpTokens` parameter from the `RunInstances` API call.

`StringNotEquals` — fires when the value is anything other than `"required"`. This covers both bad states:
- `"optional"` — IMDSv1 still allowed
- Not set at all — AWS defaults to `"optional"`

The Deny only fires when the condition is true (tokens not required). When `HttpTokens=required` is set correctly, `StringNotEquals` returns false, the Deny does not fire, and the launch proceeds.

---

## StringEquals vs StringNotEquals — When to Use Each

| Operator | Fires when | Use case |
|----------|-----------|----------|
| `StringEquals` | Value matches exactly | Allow a specific value, deny everything else via separate rule |
| `StringNotEquals` | Value does NOT match | Deny every bad value in one condition — simpler when only one correct value exists |

**deny-root.json used `StringLike`** because the root ARN contains a wildcard (`*`) in the account ID position. Wildcards require `StringLike`.

**This policy uses `StringNotEquals`** because `"required"` is an exact string — no wildcards needed, and you want to catch everything that isn't that exact value.

---

## Framework Mapping

| Framework | Control | Rationale |
|-----------|---------|-----------|
| MITRE ATT&CK | T1552.005 — Unsecured Credentials: Cloud Instance Metadata API | Direct prevention of IMDS credential theft |
| NIST CSF 2.0 | PR.AC-4 — Manage access permissions | Prevents credential exposure via metadata service |
| CIS Controls v8.1 | 4.1 — Establish Secure Configurations | IMDSv2 is the secure baseline configuration for EC2 |
| OWASP Top 10:2025 | A02 — Cryptographic Failures / A05 — Security Misconfiguration | IMDSv1 is an insecure default; this enforces the secure alternative |
