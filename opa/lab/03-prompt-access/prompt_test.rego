package finance.llm.access

import rego.v1

# ── Allow ──────────────────────────────────────────────────────────────────────

test_analyst_market_analysis_allowed if {
    allow with input as {
        "request": {"timestamp": "2026-05-18T10:00:00Z"},
        "user": {"id": "u1", "role": "analyst", "features": {"ai_access": true}},
        "prompt": {"category": "market_analysis", "model": "claude-haiku-4-5", "hash": "sha256:aaa"},
    }
}

test_trader_trade_suggestion_sonnet_allowed if {
    allow with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u2", "role": "trader", "features": {"ai_access": true}},
        "prompt": {"category": "trade_suggestion", "model": "claude-sonnet-4-6", "hash": "sha256:bbb"},
    }
}

test_compliance_officer_pii_lookup_allowed if {
    allow with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u3", "role": "compliance_officer", "features": {"ai_access": true}},
        "prompt": {"category": "pii_lookup", "model": "claude-haiku-4-5", "hash": "sha256:ccc"},
    }
}

# ── Feature flag gate ──────────────────────────────────────────────────────────

test_no_ai_access_denied if {
    not allow with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u4", "role": "analyst", "features": {"ai_access": false}},
        "prompt": {"category": "general_query", "model": "claude-haiku-4-5", "hash": "sha256:ddd"},
    }
}

test_no_ai_access_violation_message if {
    v := violations with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u4", "role": "analyst", "features": {"ai_access": false}},
        "prompt": {"category": "general_query", "model": "claude-haiku-4-5", "hash": "sha256:ddd"},
    }
    some msg in v
    contains(msg, "ai_access")
}

# ── Category role check ────────────────────────────────────────────────────────

test_analyst_cannot_request_compliance_advice if {
    not allow with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u5", "role": "analyst", "features": {"ai_access": true}},
        "prompt": {"category": "compliance_advice", "model": "claude-haiku-4-5", "hash": "sha256:eee"},
    }
}

test_analyst_cannot_request_pii_lookup if {
    not allow with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u6", "role": "analyst", "features": {"ai_access": true}},
        "prompt": {"category": "pii_lookup", "model": "claude-haiku-4-5", "hash": "sha256:fff"},
    }
}

# ── Model tier clearance ───────────────────────────────────────────────────────

test_analyst_cannot_use_opus if {
    not allow with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u7", "role": "analyst", "features": {"ai_access": true}},
        "prompt": {"category": "market_analysis", "model": "claude-opus-4-7", "hash": "sha256:ggg"},
    }
}

test_model_tier_violation_message if {
    v := violations with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u7", "role": "analyst", "features": {"ai_access": true}},
        "prompt": {"category": "market_analysis", "model": "claude-opus-4-7", "hash": "sha256:ggg"},
    }
    some msg in v
    contains(msg, "clearance")
}

test_admin_can_use_opus if {
    allow with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u8", "role": "admin", "features": {"ai_access": true}},
        "prompt": {"category": "compliance_advice", "model": "claude-opus-4-7", "hash": "sha256:hhh"},
    }
}

# ── GDPR prompt hash requirement ───────────────────────────────────────────────

test_missing_hash_denied if {
    not allow with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u9", "role": "analyst", "features": {"ai_access": true}},
        "prompt": {"category": "market_analysis", "model": "claude-haiku-4-5"},
    }
}

# ── Audit record ───────────────────────────────────────────────────────────────

test_audit_record_structure if {
    rec := audit_record with input as {
        "request": {"timestamp": "2026-05-18T10:00:00Z"},
        "user": {"id": "u10", "role": "analyst", "features": {"ai_access": true}},
        "prompt": {"category": "market_analysis", "model": "claude-haiku-4-5", "hash": "sha256:iii"},
    }
    rec.allowed == true
    rec.user_id == "u10"
    rec.prompt_hash == "sha256:iii"
    # Raw prompt text must never appear in the audit record
    not "prompt_text" in object.keys(rec)
}

test_pii_lookup_adds_gdpr_ref if {
    rec := audit_record with input as {
        "request": {"timestamp": "t"},
        "user": {"id": "u11", "role": "compliance_officer", "features": {"ai_access": true}},
        "prompt": {"category": "pii_lookup", "model": "claude-haiku-4-5", "hash": "sha256:jjj"},
    }
    some ref in rec.regulation_refs
    contains(ref, "GDPR")
}
