# Policy as Code

OPA policies provide fast deployment checks for infrastructure and platform configuration.

## Current policy

[`opa/k8s_block_privileged.rego`](opa/k8s_block_privileged.rego) checks Kubernetes workload input for privileged-container configuration.

```bash
opa check security/policy-as-code/opa/
opa test security/policy-as-code/opa/
```

The repository currently has no Rego test files, so `opa test` does not yet provide meaningful behavioral coverage. Add table-driven positive and negative cases before using the policy as a deployment gate.
