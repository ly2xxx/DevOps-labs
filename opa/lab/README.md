# Rego Lab: OPA for Regulated Finance

Hands-on policy authoring for three enforcement points common in regulated financial services.

## Prerequisites

- [OPA CLI](https://www.openpolicyagent.org/docs/latest/#1-download-opa) ≥ 0.60  
- No other dependencies — all policies run locally

```bash
opa version   # should print 0.60+
```

## Compliance context

| Policy plane    | Regulation(s)            | What it enforces                              |
|-----------------|--------------------------|-----------------------------------------------|
| K8s Admission   | PCI-DSS 6.3, DORA Art. 6 | Approved registries, pinned digests, no root  |
| K8s Admission   | PCI-DSS 7.x              | Resource limits for workload isolation        |
| API Gateway     | MiFID II Art. 16         | Role-gated trade endpoints + audit envelope   |
| API Gateway     | PCI-DSS 8.x              | MFA on PII / sensitive paths                  |
| Prompt Access   | SR 11-7                  | AI feature-flag approval before model access  |
| Prompt Access   | GDPR Art. 5              | Hash-not-raw-prompt data minimisation         |

---

## Module 0 — Rego Primer (`00-rego-primer/`)  ~15 min

Core language mechanics with finance domain examples.

**Concepts**: packages · `default` · AND/OR logic · `some` iteration · data documents · set comprehensions · partial set rules (`deny contains`)

```bash
opa test lab/00-rego-primer/ -v
```

Two TODO exercises at the bottom of `primer.rego`. Completing them makes all tests pass.

> **Windows note**: OPA loads `data.json` under `data.<drive>.*` when given an absolute path.  
> Tests mock data with `with data.<key> as {...}` (partial mock) to avoid this — see `primer_test.rego` for the pattern.

---

## Module 1 — Kubernetes Admission Control (`01-k8s-admission/`)  ~20 min

A `ValidatingAdmissionWebhook` policy that blocks non-compliant pod specs.  
Produces a structured `decision` object matching the K8s webhook response format.

```bash
# --ignore skips the example input files so they don't conflict as data documents
opa test lab/01-k8s-admission/ --ignore "input_*.json" -v

# See the admission decision for a valid pod
opa eval -d lab/01-k8s-admission/admission.rego \
  -i lab/01-k8s-admission/input_allow.json \
  "data.finance.k8s.admission.decision"

# See all collected violations for a bad pod
opa eval -d lab/01-k8s-admission/admission.rego \
  -i lab/01-k8s-admission/input_deny.json \
  "data.finance.k8s.admission.violations"
```

---

## Module 2 — API Gateway (`02-api-gateway/`)  ~20 min

RBAC with time-windowed trading restrictions and MFA enforcement.  
Produces an `audit` envelope for every decision — required by MiFID II Art. 16.

```bash
opa test lab/02-api-gateway/ --ignore "input_*.json" -v

opa eval -d lab/02-api-gateway/gateway.rego \
  -i lab/02-api-gateway/input_allow.json \
  "data.finance.api.gateway.audit"

opa eval -d lab/02-api-gateway/gateway.rego \
  -i lab/02-api-gateway/input_deny.json \
  "data.finance.api.gateway.deny_reasons"
```

---

## Module 3 — Prompt-Access Layer (`03-prompt-access/`)  ~20 min

LLM access control implementing SR 11-7 model risk governance.  
Enforces feature-flag approval, category-based role requirements, model tier clearance,  
and emits an `audit_record` that never contains the raw prompt text.

```bash
opa test lab/03-prompt-access/ --ignore "input_*.json" -v

opa eval -d lab/03-prompt-access/prompt.rego \
  -i lab/03-prompt-access/input_allow.json \
  "data.finance.llm.access.audit_record"

opa eval -d lab/03-prompt-access/prompt.rego \
  -i lab/03-prompt-access/input_deny.json \
  "data.finance.llm.access.violations"
```

---

## Composition (`compose/`)

Shows how all three modules load as one bundle and compose into a unified decision.

```bash
opa eval \
  -d lab/01-k8s-admission/admission.rego \
  -d lab/02-api-gateway/gateway.rego \
  -d lab/03-prompt-access/prompt.rego \
  -d compose/main.rego \
  -i lab/01-k8s-admission/input_allow.json \
  "data.finance.unified.all_violations"
```

---

## Key patterns across modules

| Pattern                        | Finance rationale                                              |
|--------------------------------|----------------------------------------------------------------|
| `default allow := false`       | Deny-by-default — PCI-DSS principle of least privilege        |
| `deny contains msg` / `violations contains msg` | Collect ALL failures; surface every reason to the SIEM |
| `audit` / `audit_record` rule  | Immutable decision record for MiFID II / SR 11-7 audit trails |
| `concat("; ", violations)`     | Human-readable K8s webhook rejection reason                   |
