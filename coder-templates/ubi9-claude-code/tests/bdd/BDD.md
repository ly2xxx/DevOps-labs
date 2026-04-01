# BDD SSH Echo Tests

Behaviour-Driven Development (BDD) tests for verifying SSH connectivity and basic command execution in a Coder workspace, using Python's [Behave](https://behave.readthedocs.io/) framework.

Tests are written in plain English (**Gherkin** syntax) and wired to Python step definitions, making them readable by developers and non-developers alike.

---

## File Structure

```
tests/bdd/
├── BDD.md                          ← You are here
├── requirements.txt                ← Python dependencies (behave, paramiko)
└── features/
    ├── environment.py              ← Lifecycle hooks: before_all, before_scenario, after_scenario
    ├── ssh_echo.feature            ← Gherkin scenarios (Given / When / Then)
    └── steps/
        └── ssh_echo_steps.py      ← Python step definitions wired to the feature file
```

### What each file does

| File | Purpose |
|------|---------|
| `ssh_echo.feature` | Plain-English test scenarios written in Gherkin. This is the source of truth for what is being tested. |
| `steps/ssh_echo_steps.py` | Python functions decorated with `@given`, `@when`, `@then` that match and execute each Gherkin line. |
| `environment.py` | Global hooks — verifies the Coder CLI and workspace are reachable before any tests run. |
| `requirements.txt` | Pip dependencies needed to run the suite. |

---

## Running the Tests

### 1. Install dependencies

```bash
pip install -r tests/bdd/requirements.txt
```

### 2. Run all scenarios

```bash
cd tests/bdd
behave
```

### 3. Run with verbose output

```bash
behave --no-capture -v
```

### 4. Run a single scenario by name

```bash
behave --name "Basic echo command"
```

### 5. Override the workspace name

```bash
CODER_WORKSPACE=my-claude-workspace behave
```

---

## Prerequisites

- Coder CLI installed and authenticated (`coder version` should work)
- Target workspace is running (`coder start my-claude-workspace`)
- Python 3.8+
