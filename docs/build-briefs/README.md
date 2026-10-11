# Build Briefs

These three projects form one release platform:

1. **[Infrastructure as code with drift detection](01-iac-drift-detection.md):** Terraform builds the environment and a scheduled plan catches drift.
2. **[GitOps delivery with automatic rollback](02-gitops-auto-rollback.md):** merging a PR deploys a canary, and a bad release reverts on its own.
3. **[SLOs and error budgets](03-slo-error-budgets.md):** reliability is measured the way SRE teams measure it, and the rollback in #2 uses the same metrics to decide.

Recommended build order: **2 → 3 → 1**. The rollback demo is the centerpiece, SLOs feed its rollback decision, and Terraform is the foundation once the rest works locally.

Each brief covers:

- the outcome
- what the project proves
- the requirements
- the evidence that counts as done
- gotchas already found

None of these projects is implemented yet. Each brief's checklist is the work.

Versions listed in the briefs were current releases at least two weeks old on 2026-10-11. Re-check them before pinning.
