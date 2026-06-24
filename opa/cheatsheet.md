# Open Policy Agent (OPA) Cheat Sheet

Quick reference for OPA CLI commands and common Rego syntax patterns.

---

## 🚀 OPA CLI Commands

### Basic Validation & Formatting
```bash
# Check syntax of Rego files
opa check policy.rego
opa check --strict policy.rego

# Automatically format Rego files
opa fmt -w policy.rego
```

### Policy Evaluation
```bash
# Evaluate a query with input data
opa eval -d policy.rego -i input.json "data.main.allow"

# Evaluate and get raw JSON output
opa eval -d policy.rego -i input.json "data.main.allow" --format json

# Evaluate query without input
opa eval "1 + 2"
```

### Testing
```bash
# Run all tests in current directory
opa test . -v

# Run tests in specific folder
opa test lab/00-rego-primer/ -v

# Run tests ignoring specific files (e.g., input files)
opa test lab/01-k8s-admission/ --ignore "input_*.json" -v

# Run tests matching a specific naming pattern
opa test . --run "test_allow_*" -v
```

### OPA Server (Interactive / API)
```bash
# Start OPA interactive shell (REPL)
opa run

# Start OPA as a background server api
opa run --server --addr :8181

# Start OPA server with local policies loaded
opa run --server -d policy.rego
```

### Bundling & Building
```bash
# Build policy bundle
opa build -b . -o bundle.tar.gz
```

---

## 📝 Rego Language Syntax Quick Reference

### 1. Variables and Assignment
```rego
# Assignment (local variable)
x := 10

# Rule definition (evaluates to true/false or value)
allow {
    input.user == "admin"
}
```

### 2. Logical Operators
- **AND**: Multiple expressions in a single body are ANDed.
- **OR**: Multiple rule blocks with the same name are ORed.

```rego
# AND: user is admin AND method is GET
allow {
    input.user == "admin"
    input.method == "GET"
}

# OR: user is admin OR user is auditor
authorized {
    input.user == "admin"
}
authorized {
    input.user == "auditor"
}
```

### 3. Iteration & Quantification (`some` and `every`)
```rego
# Check if at least one item matches (any)
has_root_user {
    some container in input.request.object.spec.containers
    container.securityContext.runAsRoot == true
}

# Check if ALL items match
all_containers_non_root {
    every container in input.request.object.spec.containers {
        container.securityContext.runAsNonRoot == true
    }
}
```

### 4. Sets and Comprehensions
```rego
# Array comprehension (returns list of names)
container_names := [c.name | some c in input.request.object.spec.containers]

# Set comprehension (returns set of forbidden registries)
bad_registries := {r |
    some r in input.registries
    not startswith(r, "approved.registry.com")
}
```

---

## 🎯 Common Policy Patterns in DevOps

### Deny-by-default
```rego
package main

# Default deny rule
default allow := false

# Allow if criteria met
allow {
    input.user == "admin"
}
```

### Collecting Multiple Violations (Kubernetes Admission)
```rego
package k8s.admission

# Collect all validation violations
violations contains msg {
    some container in input.request.object.spec.containers
    not container.resources.limits.cpu
    msg := sprintf("Container '%v' has no CPU limit set", [container.name])
}

violations contains msg {
    some container in input.request.object.spec.containers
    container.securityContext.runAsRoot == true
    msg := sprintf("Container '%v' is configured to run as root", [container.name])
}

# Standard K8s decision object
decision = {
    "allowed": false,
    "status": {
        "reason": concat("; ", violations)
    }
} {
    count(violations) > 0
}

default decision = {
    "allowed": true
}
```

---

## 📚 Resources
- [Official Rego Policy Language Reference](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [OPA CLI Reference](https://www.openpolicyagent.org/docs/latest/cli/)
- [Playground (Rego Editor)](https://play.openpolicyagent.org/)
