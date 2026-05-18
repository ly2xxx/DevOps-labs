package finance.k8s.admission

import rego.v1

# Shared helper: a fully compliant pod spec
compliant_pod := {
    "request": {
        "uid": "test-001",
        "object": {
            "metadata": {
                "name": "app",
                "namespace": "trading",
                "labels": {"compliance-zone": "pci-cardholder"},
            },
            "spec": {
                "containers": [{
                    "name": "app",
                    "image": "registry.finco.internal/app:v2.0.1",
                    "securityContext": {
                        "privileged": false,
                        "capabilities": {"add": []},
                    },
                    "resources": {"limits": {"cpu": "250m", "memory": "256Mi"}},
                }],
            },
        },
    },
}

# ── Allow ──────────────────────────────────────────────────────────────────────

test_compliant_pod_allowed if {
    d := decision with input as compliant_pod
    d.allowed == true
}

test_compliant_pod_no_violations if {
    v := violations with input as compliant_pod
    count(v) == 0
}

# ── Registry check ─────────────────────────────────────────────────────────────

test_external_registry_blocked if {
    pod := json.patch(compliant_pod, [{
        "op": "replace",
        "path": "/request/object/spec/containers/0/image",
        "value": "docker.io/nginx:v1.0.0",
    }])
    v := violations with input as pod
    some msg in v
    contains(msg, "unapproved registry")
}

# ── Latest tag check ───────────────────────────────────────────────────────────

test_latest_tag_blocked if {
    pod := json.patch(compliant_pod, [{
        "op": "replace",
        "path": "/request/object/spec/containers/0/image",
        "value": "registry.finco.internal/app:latest",
    }])
    v := violations with input as pod
    some msg in v
    contains(msg, "':latest'")
}

# ── Resource limits ────────────────────────────────────────────────────────────

test_missing_memory_limit_blocked if {
    pod := json.patch(compliant_pod, [{
        "op": "replace",
        "path": "/request/object/spec/containers/0/resources",
        "value": {"limits": {"cpu": "250m"}},
    }])
    v := violations with input as pod
    some msg in v
    contains(msg, "memory limit")
}

# ── Privileged / capabilities ──────────────────────────────────────────────────

test_privileged_container_blocked if {
    pod := json.patch(compliant_pod, [{
        "op": "replace",
        "path": "/request/object/spec/containers/0/securityContext/privileged",
        "value": true,
    }])
    v := violations with input as pod
    some msg in v
    contains(msg, "privileged mode")
}

test_sys_admin_cap_blocked if {
    pod := json.patch(compliant_pod, [{
        "op": "replace",
        "path": "/request/object/spec/containers/0/securityContext/capabilities/add",
        "value": ["SYS_ADMIN"],
    }])
    v := violations with input as pod
    some msg in v
    contains(msg, "SYS_ADMIN")
}

# ── Compliance label ───────────────────────────────────────────────────────────

test_missing_compliance_label_blocked if {
    pod := json.patch(compliant_pod, [{
        "op": "remove",
        "path": "/request/object/metadata/labels",
    }])
    v := violations with input as pod
    some msg in v
    contains(msg, "compliance-zone")
}

# ── Multiple violations at once ────────────────────────────────────────────────

test_rogue_pod_multiple_violations if {
    rogue := {
        "request": {"uid": "bad", "object": {
            "metadata": {"name": "rogue", "namespace": "trading"},
            "spec": {"containers": [{
                "name": "app",
                "image": "docker.io/nginx:latest",
                "securityContext": {
                    "privileged": true,
                    "capabilities": {"add": ["SYS_ADMIN"]},
                },
                "resources": {"limits": {}},
            }]},
        }},
    }
    v := violations with input as rogue
    count(v) >= 5
}
