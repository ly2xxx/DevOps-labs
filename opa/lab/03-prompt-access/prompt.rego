package finance.llm.access

import rego.v1

# ── Category → minimum role matrix (SR 11-7 model risk governance) ────────────
category_roles := {
    "general_query":     {"analyst", "trader", "compliance_officer", "admin"},
    "market_analysis":   {"analyst", "trader", "admin"},
    "trade_suggestion":  {"trader", "admin"},
    "compliance_advice": {"compliance_officer", "admin"},
    "pii_lookup":        {"compliance_officer", "admin"},
    "model_explanation": {"model_risk_officer", "admin"},
}

# ── Model tier clearance ───────────────────────────────────────────────────────
# More capable models have higher risk exposure; higher clearance gates access.
model_tier := {
    "claude-haiku-4-5":  1,
    "claude-sonnet-4-6": 2,
    "claude-opus-4-7":   3,
}

role_clearance := {
    "analyst":            1,
    "trader":             2,
    "compliance_officer": 2,
    "model_risk_officer": 3,
    "admin":              3,
}

# ── Decision ───────────────────────────────────────────────────────────────────
default allow := false

allow if {
    count(violations) == 0
}

# ── Violation collectors ───────────────────────────────────────────────────────

# Feature flag gate — ai_access requires explicit compliance approval per SR 11-7
violations contains msg if {
    not input.user.features.ai_access
    msg := "user lacks 'ai_access' feature — compliance sign-off required (SR 11-7 §4)"
}

# Category existence check before role check to give a clear error
violations contains msg if {
    not category_roles[input.prompt.category]
    msg := sprintf("unknown prompt category '%s' — declare a recognised category", [input.prompt.category])
}

# Role must satisfy the category's minimum requirement
violations contains msg if {
    input.user.features.ai_access
    allowed_roles := category_roles[input.prompt.category]
    not allowed_roles[input.user.role]
    msg := sprintf(
        "role '%s' cannot access category '%s'",
        [input.user.role, input.prompt.category],
    )
}

# Model clearance: analyst (level 1) cannot use Opus (level 3)
violations contains msg if {
    user_level := role_clearance[input.user.role]
    required_level := model_tier[input.prompt.model]
    user_level < required_level
    msg := sprintf(
        "model '%s' requires clearance %d; role '%s' has %d",
        [input.prompt.model, required_level, input.user.role, user_level],
    )
}

# GDPR Art. 5 data minimisation — raw prompts must never reach the policy engine
violations contains msg if {
    not input.prompt.hash
    msg := "prompt.hash required — policy engine must receive hash, not raw prompt text"
}

# ── Audit record (SR 11-7 §5 — model use logging) ─────────────────────────────
# Raw prompt text is never stored; only the hash and metadata travel to the log.
audit_record := {
    "allowed":         allow,
    "user_id":         input.user.id,
    "role":            input.user.role,
    "category":        input.prompt.category,
    "model":           input.prompt.model,
    "prompt_hash":     input.prompt.hash,
    "violations":      violations,
    "regulation_refs": regulation_refs,
    "timestamp":       input.request.timestamp,
}

regulation_refs := array.concat(
    ["SR 11-7 (Model Risk Management)"],
    pii_refs,
)

pii_refs := ["GDPR Art. 5 (data minimisation)"] if {
    input.prompt.category == "pii_lookup"
} else := []
