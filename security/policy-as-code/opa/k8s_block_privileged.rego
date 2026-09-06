package kubernetes.admission

# 1. THE RULE: We want to 'deny' if certain conditions are met
deny[msg] if {
    # Is this a Pod creation request?
    input.request.kind.kind == "Pod"

    # 2. THE VIOLATION: Look inside the container spec
    # The [_] means "Check EVERY container in the list"
    container := input.request.object.spec.containers[_]

    # Is the 'privileged' flag set to true?
    container.securityContext.privileged == true

    # 3. THE VERDICT: If true, return this error message
    msg := sprintf("Pod %v is REJECTED: Privileged containers are a high security risk.", [input.request.object.metadata.name])
}
