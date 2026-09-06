# Security Controls

Preventive and detective guardrails are kept close to the infrastructure they protect.

## Components

- [`policies/aws/`](policies/aws/README.md): AWS Organizations SCPs, an IAM permission boundary, and privilege-escalation guidance
- [`policy-as-code/`](policy-as-code/README.md): OPA policies for deployment-time checks
- [`supply-chain/`](supply-chain/README.md): checksum validation, SBOMs, vulnerability scanning, and image signing

These files are examples until they have been tested against the target organization, account, or cluster. Static validation does not establish compliance or operating effectiveness.
