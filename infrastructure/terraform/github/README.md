# GitHub Terraform

This directory is reserved for a Terraform root module that manages GitHub organization and repository settings, such as teams, rulesets, environments, and Actions configuration.

GitHub administration has a separate provider, credential boundary, and change lifecycle from AWS infrastructure. Use the smallest token or GitHub App permissions possible, protect the state because it can expose repository metadata, and import existing objects before management.

No active GitHub Terraform configuration exists yet.
