# AWS Development Environment

This directory is reserved for the deployable development root module. It may compose modules from [`../../modules/`](../../modules/README.md) but must own its provider configuration, backend configuration, variables, and outputs.

Use a development-specific state key and short-lived deployment identity. Add cost tags, budgets, logging, and safe defaults from the first implementation. Development changes still require a reviewed plan and documented teardown impact.
