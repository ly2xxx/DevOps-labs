package finance.unified

import rego.v1

# Bundle composition pattern (Composing OPA Solutions — aserto.com/blog/composing-opa-solutions).
#
# When all three modules are loaded into one bundle (`opa eval -d lab/ -d compose/`),
# their rules are reachable under the `data` document by package path.
# This module composes a unified allow from all three planes.
#
# In production each OPA sidecar/plugin evaluates its own policy against its own
# input format — this module is for bundle-level integration tests and audit roll-ups.

default allow := false

allow if {
    # K8s admission passed — no pod violations
    count(data.finance.k8s.admission.violations) == 0

    # API request authorised
    data.finance.api.gateway.allow

    # LLM prompt access cleared
    data.finance.llm.access.allow
}

# Aggregated violation surface — ships to SIEM as a single structured event.
# Empty sets / false values indicate no issues on that plane.
all_violations := {
    "k8s":     data.finance.k8s.admission.violations,
    "gateway": data.finance.api.gateway.deny_reasons,
    "llm":     data.finance.llm.access.violations,
}

# Cross-plane audit envelope
summary := {
    "allowed":        allow,
    "all_violations": all_violations,
    "planes": {
        "k8s_decision":     data.finance.k8s.admission.decision,
        "gateway_audit":    data.finance.api.gateway.audit,
        "llm_audit_record": data.finance.llm.access.audit_record,
    },
}
