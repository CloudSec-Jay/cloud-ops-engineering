# CloudFormation

AWS templates in this directory demonstrate infrastructure provisioning and operational controls.

| Template | Purpose | Maturity note |
|---|---|---|
| `network.yaml` | VPC, public/private subnets, routing, NAT, and default security-group handling | Review NAT cost and availability design |
| `security.yaml` | ALB, web, and database security-group tiers | Requires network stack inputs and environment testing |
| `contact-form.yaml` | API Gateway, Lambda, DynamoDB, WAF, logs, and throttling | Application example retained for serverless operations |
| `detection-pipeline.yaml` | CloudTrail, GuardDuty, KMS, S3, and Wazuh access | Lab design creates an IAM access key; replace with role-based access for production |
| `detection-pipeline-pass2.yaml` | GuardDuty publishing destination after base resources exist | Requires outputs from the first deployment |

## Validate and review

```bash
cfn-lint infrastructure/cloudformation/*.yaml
checkov --directory infrastructure/cloudformation
aws cloudformation validate-template --template-body file://infrastructure/cloudformation/network.yaml
```

Create and inspect a change set before deployment. Confirm replacement behavior, IAM capabilities, retained resources, KMS deletion windows, log-bucket retention, and rollback behavior.

The detection pipeline currently exposes access-key material through stack outputs. Treat it as a lab artifact, never publish its outputs, and prefer instance roles, task roles, or another short-lived credential mechanism in a real environment.
