package finance.api.gateway

import rego.v1

# ── Allow ──────────────────────────────────────────────────────────────────────

test_trader_in_window_allowed if {
    allow with input as {
        "request": {"path": "/api/v1/trades", "hour_utc": 10, "timestamp": "2026-05-18T10:00:00Z"},
        "jwt": {"sub": "u1", "role": "trader", "amr": ["password"]},
    }
}

test_analyst_portfolio_allowed if {
    allow with input as {
        "request": {"path": "/api/v1/portfolio", "hour_utc": 9, "timestamp": "2026-05-18T09:00:00Z"},
        "jwt": {"sub": "u2", "role": "analyst", "amr": ["password"]},
    }
}

# ── JWT validation ─────────────────────────────────────────────────────────────

test_missing_jwt_denied if {
    not allow with input as {
        "request": {"path": "/api/v1/trades", "hour_utc": 10, "timestamp": "t"},
        "jwt": {"sub": "", "role": ""},
    }
}

test_missing_jwt_reason if {
    reasons := deny_reasons with input as {
        "request": {"path": "/api/v1/trades", "hour_utc": 10, "timestamp": "t"},
        "jwt": {"sub": "", "role": ""},
    }
    some r in reasons
    contains(r, "JWT")
}

# ── Role check ─────────────────────────────────────────────────────────────────

test_analyst_cannot_execute_trade if {
    not allow with input as {
        "request": {"path": "/api/v1/trades/execute", "hour_utc": 10, "timestamp": "t"},
        "jwt": {"sub": "u3", "role": "analyst", "amr": ["password", "mfa"]},
    }
}

test_role_violation_reason if {
    reasons := deny_reasons with input as {
        "request": {"path": "/api/v1/trades/execute", "hour_utc": 10, "timestamp": "t"},
        "jwt": {"sub": "u3", "role": "analyst", "amr": ["password", "mfa"]},
    }
    some r in reasons
    contains(r, "not permitted")
}

# ── MFA check ──────────────────────────────────────────────────────────────────

test_execute_without_mfa_denied if {
    not allow with input as {
        "request": {"path": "/api/v1/trades/execute", "hour_utc": 10, "timestamp": "t"},
        "jwt": {"sub": "u4", "role": "trader", "amr": ["password"]},
    }
}

test_execute_with_mfa_and_window_allowed if {
    allow with input as {
        "request": {"path": "/api/v1/trades/execute", "hour_utc": 14, "timestamp": "t"},
        "jwt": {"sub": "u5", "role": "trader", "amr": ["password", "mfa"]},
    }
}

# ── Time window check ──────────────────────────────────────────────────────────

test_trading_after_hours_denied if {
    not allow with input as {
        "request": {"path": "/api/v1/trades", "hour_utc": 19, "timestamp": "t"},
        "jwt": {"sub": "u6", "role": "trader", "amr": ["password"]},
    }
}

test_after_hours_reason if {
    reasons := deny_reasons with input as {
        "request": {"path": "/api/v1/trades", "hour_utc": 21, "timestamp": "t"},
        "jwt": {"sub": "u6", "role": "trader", "amr": ["password"]},
    }
    some r in reasons
    contains(r, "08:00")
}

# Non-trading paths are not time-restricted
test_portfolio_after_hours_allowed if {
    allow with input as {
        "request": {"path": "/api/v1/portfolio", "hour_utc": 22, "timestamp": "t"},
        "jwt": {"sub": "u7", "role": "analyst", "amr": ["password"]},
    }
}

# ── Audit envelope ─────────────────────────────────────────────────────────────

test_audit_contains_subject if {
    a := audit with input as {
        "request": {"path": "/api/v1/portfolio", "hour_utc": 10, "timestamp": "2026-05-18T10:00:00Z"},
        "jwt": {"sub": "user-audit", "role": "analyst", "amr": ["password"]},
    }
    a.subject == "user-audit"
    a.allowed == true
}
