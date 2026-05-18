package finance.api.gateway

import rego.v1

# ── Permission matrix ──────────────────────────────────────────────────────────
# In production this would live in a data bundle fetched from a policy store.
endpoint_roles := {
    "/api/v1/trades":             {"trader", "admin"},
    "/api/v1/trades/execute":     {"trader"},
    "/api/v1/portfolio":          {"analyst", "trader", "admin"},
    "/api/v1/compliance/reports": {"compliance_officer", "admin"},
    "/api/v1/customers/pii":      {"compliance_officer", "admin"},
    "/api/v1/ai/query":           {"analyst", "trader", "admin"},
}

# MFA required for high-risk paths (PCI-DSS 8.4.2)
mfa_required := {
    "/api/v1/trades/execute",
    "/api/v1/customers/pii",
    "/api/v1/compliance/reports",
}

# Trading endpoints are only accessible during market hours 08:00–18:00 UTC
# (covers EMEA open + US morning; adjust per exchange calendar in production)
trading_paths := {"/api/v1/trades", "/api/v1/trades/execute"}

# ── Decision ───────────────────────────────────────────────────────────────────
default allow := false

allow if {
    count(deny_reasons) == 0
}

# ── Denial collectors ──────────────────────────────────────────────────────────

deny_reasons contains reason if {
    not valid_jwt
    reason := "missing or malformed JWT — sub and role claims required"
}

deny_reasons contains reason if {
    valid_jwt
    path := input.request.path
    not endpoint_roles[path]
    reason := sprintf("unknown endpoint '%s'", [path])
}

deny_reasons contains reason if {
    valid_jwt
    required := endpoint_roles[input.request.path]
    not required[input.jwt.role]
    reason := sprintf("role '%s' not permitted on %s", [input.jwt.role, input.request.path])
}

deny_reasons contains reason if {
    valid_jwt
    mfa_required[input.request.path]
    not mfa_satisfied
    reason := sprintf("%s requires MFA — 'mfa' amr claim missing from token", [input.request.path])
}

# MiFID II Article 16: trading endpoints restricted to market hours
deny_reasons contains reason if {
    valid_jwt
    trading_paths[input.request.path]
    not within_trading_window
    reason := sprintf(
        "trading path %s only accessible 08:00–18:00 UTC (current hour: %d)",
        [input.request.path, input.request.hour_utc],
    )
}

# ── Helpers ────────────────────────────────────────────────────────────────────

valid_jwt if {
    input.jwt.sub != ""
    input.jwt.role != ""
}

mfa_satisfied if {
    some amr in input.jwt.amr
    amr == "mfa"
}

within_trading_window if {
    input.request.hour_utc >= 8
    input.request.hour_utc < 18
}

# ── Audit envelope (MiFID II Art. 16 — immutable decision record) ──────────────
audit := {
    "allowed":   allow,
    "subject":   input.jwt.sub,
    "role":      input.jwt.role,
    "path":      input.request.path,
    "reasons":   deny_reasons,
    "timestamp": input.request.timestamp,
}
