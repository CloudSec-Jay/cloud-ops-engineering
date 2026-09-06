# AWS Log Ingestion into Wazuh

This example routes CloudTrail and GuardDuty data to an encrypted S3 bucket and configures the Wazuh `aws-s3` module to poll that bucket.

## Repository components

- [`infrastructure/cloudformation/detection-pipeline.yaml`](../../../../../infrastructure/cloudformation/detection-pipeline.yaml): CloudTrail, GuardDuty, KMS, S3, and a Wazuh reader identity
- [`infrastructure/cloudformation/detection-pipeline-pass2.yaml`](../../../../../infrastructure/cloudformation/detection-pipeline-pass2.yaml): optional split deployment of the GuardDuty publishing destination
- [`manager-configs/manager.conf`](../../manager-configs/manager.conf): example Wazuh `aws-s3` configuration with placeholders
- [`containers/compose/wazuh-single-node/.env.example`](../../../../../containers/compose/wazuh-single-node/.env.example): local environment-variable names

## Data flow

```text
CloudTrail ----\
                -> KMS-encrypted S3 -> Wazuh aws-s3 module -> rules -> alerts
GuardDuty -----/
```

## Validate before deployment

```bash
cfn-lint infrastructure/cloudformation/detection-pipeline.yaml
cfn-lint infrastructure/cloudformation/detection-pipeline-pass2.yaml
checkov --directory infrastructure/cloudformation
```

Create and inspect a CloudFormation change set in a non-production account. The main template creates named IAM resources, so deployment requires the appropriate IAM capability acknowledgement.

## Credential warning

The current lab template creates an IAM user and access key and returns credential material through CloudFormation outputs. That design is not suitable for production and stack-output access must be treated as sensitive. Prefer an instance profile, container task role, workload identity, or another short-lived credential source supported by the Wazuh deployment environment.

Never place credentials directly in `manager.conf`, Git history, command output, or documentation. If the lab key is created, retrieve it through an authorized channel, store it only in the local ignored environment file, restrict access, and rotate or delete it after testing.

## Verification

After configuration and manager restart:

1. Confirm the Wazuh module starts without authentication or bucket-policy errors.
2. Generate a harmless test event in the non-production AWS account.
3. Verify delivery to the expected S3 prefix.
4. Verify Wazuh processes the object and creates the expected event.
5. Record redacted evidence and test the failure path with denied access.

Do not treat example bucket names, account placeholders, or log messages as deployment evidence.
