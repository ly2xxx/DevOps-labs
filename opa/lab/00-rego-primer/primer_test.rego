package finance.primer

import rego.v1

# ── allow ──────────────────────────────────────────────────────────────────────

test_allow_authenticated_analyst if {
    allow with input as {
        "user": {"authenticated": true, "role": "analyst", "roles": ["analyst"], "tier": "professional"},
        "trade": {"amount": 100},
    }
}

test_allow_admin_without_auth_flag if {
    # Admin branch does not check `authenticated` — OR logic, second rule head
    allow with input as {
        "user": {"authenticated": false, "role": "admin", "roles": ["admin"], "tier": "institutional"},
        "trade": {"amount": 0},
    }
}

test_deny_unauthenticated_analyst if {
    not allow with input as {
        "user": {"authenticated": false, "role": "analyst", "roles": ["analyst"], "tier": "retail"},
        "trade": {"amount": 0},
    }
}

# ── has_approved_role ──────────────────────────────────────────────────────────

test_has_approved_role_trader if {
    has_approved_role with input as {"user": {"roles": ["viewer", "trader"]}}
}

test_no_approved_role if {
    not has_approved_role with input as {"user": {"roles": ["viewer", "guest"]}}
}

# ── within_daily_limit ─────────────────────────────────────────────────────────
# Use `with data.daily_limits as` (partial mock) rather than `with data as`
# to avoid replacing the entire data document, which would include the test
# package itself and trigger OPA's recursion detector.

test_within_limit_professional if {
    within_daily_limit
        with input as {"user": {"tier": "professional"}, "trade": {"amount": 499999}}
        with data.daily_limits as {"retail": 10000, "professional": 500000, "institutional": 50000000}
}

test_exceeds_limit_professional if {
    not within_daily_limit
        with input as {"user": {"tier": "professional"}, "trade": {"amount": 500001}}
        with data.daily_limits as {"professional": 500000}
}

test_institutional_large_trade if {
    within_daily_limit
        with input as {"user": {"tier": "institutional"}, "trade": {"amount": 49000000}}
        with data.daily_limits as {"institutional": 50000000}
}

# ── deny (partial set) ─────────────────────────────────────────────────────────

test_deny_collects_all_reasons if {
    reasons := deny
        with input as {"user": {"authenticated": false, "roles": [], "tier": "retail"}, "trade": {"amount": 99999999}}
        with data.daily_limits as {"retail": 10000}
    # Unauthenticated + no approved role + over limit = 3 reasons
    count(reasons) == 3
}

test_deny_empty_when_valid if {
    reasons := deny
        with input as {"user": {"authenticated": true, "role": "trader", "roles": ["trader"], "tier": "institutional"}, "trade": {"amount": 1000}}
        with data.daily_limits as {"institutional": 50000000}
    count(reasons) == 0
}

# ── unapproved_roles ──────────────────────────────────────────────────────────

test_unapproved_roles_set if {
    result := unapproved_roles
        with input as {"user": {"roles": ["analyst", "guest", "viewer"]}}
        with data.approved_roles as ["analyst", "trader", "compliance_officer", "admin"]
    result == {"guest", "viewer"}
}
