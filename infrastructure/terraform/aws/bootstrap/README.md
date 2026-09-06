# AWS Terraform Bootstrap

This directory is reserved for the one-time foundation required by later Terraform root modules, typically an encrypted and versioned S3 state bucket plus a supported locking mechanism.

Bootstrap resources have a different lifecycle from application infrastructure. Before adding code, document:

- who can initialize, read, update, and recover state
- how deletion and replacement are prevented
- encryption-key ownership and recovery
- lock behavior and failure recovery
- backup/version restoration
- how the bootstrap's initial local state is secured or migrated

Do not place ordinary environment resources here.
