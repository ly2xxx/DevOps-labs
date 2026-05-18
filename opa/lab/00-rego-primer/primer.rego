package finance.primer

import rego.v1

# ── CONCEPT 1: Default values ─────────────────────────────────────────────────
# Without `default`, a rule is `undefined` when its body fails.
# Callers that check `rule == false` will miss `undefined` — always set defaults.
default allow := false

# ── CONCEPT 2: AND logic — all expressions in a body must be true ─────────────
allow if {
    input.user.authenticated == true
    input.user.role == "analyst"
}

# ── CONCEPT 3: OR logic — multiple heads with the same name are unified ───────
# allow is true if the body above succeeds OR this one does.
allow if {
    input.user.role == "admin"
}

# ── CONCEPT 4: `some` — existential iteration over a collection ───────────────
# True when the user holds ANY role that appears in the approved set.
default has_approved_role := false

has_approved_role if {
    approved := {"analyst", "trader", "compliance_officer", "admin"}
    some role in input.user.roles
    approved[role]
}

# ── CONCEPT 5: Data documents ─────────────────────────────────────────────────
# data.json files in the same directory are automatically loaded into `data`.
# In a bundle the directory path becomes the namespace prefix.
default within_daily_limit := false

within_daily_limit if {
    limit := data.daily_limits[input.user.tier]
    input.trade.amount <= limit
}

# ── CONCEPT 6: Set comprehension — build a new set from iteration ─────────────
# Collect every role the user holds that is NOT in the approved list.
unapproved_roles := {role |
    some role in input.user.roles
    not role in data.approved_roles
}

# ── CONCEPT 7: Partial set rule — accumulates ALL matching values ──────────────
# Unlike a boolean rule that stops at the first true/false, a partial set rule
# keeps iterating and collects every reason. Callers see the full picture.
deny contains reason if {
    not input.user.authenticated
    reason := "user is not authenticated"
}

# No authentication guard here — collect ALL violations regardless of auth state
deny contains reason if {
    not has_approved_role
    reason := "user holds no approved role"
}

deny contains reason if {
    not within_daily_limit
    reason := sprintf(
        "trade amount %v exceeds daily limit for tier '%s'",
        [input.trade.amount, input.user.tier],
    )
}

# ── TODO EXERCISE A ────────────────────────────────────────────────────────────
# Write a rule `can_view_pnl` that is true only when ALL of:
#   - allow is true
#   - input.user.clearance_level >= 2
#   - input.user.suspended is NOT true
#
# default can_view_pnl := false
# can_view_pnl if { ... }

# ── TODO EXERCISE B ────────────────────────────────────────────────────────────
# Write `large_trades` as a set comprehension that collects the `id` field of
# every item in input.trades where trade.amount > 1_000_000.
# Hint: `some t in input.trades`
#
# large_trades := { ... }
