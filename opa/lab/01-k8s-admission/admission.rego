package finance.k8s.admission

import rego.v1

# Mirrors the Kubernetes ValidatingAdmissionWebhook response shape.
# An empty violations set → allowed; any violation → denied with reasons joined.
decision := {"allowed": true} if {
    count(violations) == 0
}

decision := {"allowed": false, "status": {"reason": msg}} if {
    count(violations) > 0
    msg := concat("; ", violations)
}

# ── Violation collectors ───────────────────────────────────────────────────────
# Each `violations contains` branch independently tests one control.
# All matching branches contribute to the set — callers see every failure.

# PCI-DSS 6.3.3 / DORA Art. 6: images must come from the internal registry
violations contains msg if {
    some c in input.request.object.spec.containers
    not startswith(c.image, "registry.finco.internal/")
    msg := sprintf("container '%s' uses unapproved registry: %s", [c.name, c.image])
}

# Audit trail: :latest is non-deterministic; pinned digest required for change log
violations contains msg if {
    some c in input.request.object.spec.containers
    endswith(c.image, ":latest")
    msg := sprintf("container '%s' uses ':latest' — pinned digest required", [c.name])
}

# PCI-DSS 7.x: resource limits enforce workload isolation
violations contains msg if {
    some c in input.request.object.spec.containers
    not c.resources.limits.memory
    msg := sprintf("container '%s' missing memory limit", [c.name])
}

violations contains msg if {
    some c in input.request.object.spec.containers
    not c.resources.limits.cpu
    msg := sprintf("container '%s' missing CPU limit", [c.name])
}

# PCI-DSS 7.1: no privileged containers in cardholder data zones
violations contains msg if {
    some c in input.request.object.spec.containers
    c.securityContext.privileged == true
    msg := sprintf("container '%s' requests privileged mode — forbidden", [c.name])
}

# Capability allow-list: SYS_ADMIN allows container escapes
violations contains msg if {
    some c in input.request.object.spec.containers
    some cap in c.securityContext.capabilities.add
    cap in {"SYS_ADMIN", "NET_ADMIN", "SYS_PTRACE"}
    msg := sprintf("container '%s' requests forbidden capability: %s", [c.name, cap])
}

# Audit segmentation: pods must declare which compliance zone they belong to
violations contains msg if {
    not input.request.object.metadata.labels["compliance-zone"]
    msg := "pod missing required label 'compliance-zone'"
}
