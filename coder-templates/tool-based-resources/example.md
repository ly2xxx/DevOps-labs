# How Dynamic Parameters, Presets, and Locals Work Together

## The Three Layers

### 1. `locals` — pure Terraform, runs server-side at plan time

```hcl
locals {
  tool_profiles = {
    intellij = { cpu = 4, memory = 6, disk = 10 }
    vscode   = { cpu = 2, memory = 4, disk = 5 }
    cursor   = { cpu = 2, memory = 4, disk = 5 }
  }

  selected = jsondecode(data.coder_parameter.tools.value)

  profile = {
    cpu    = max across selected tools
    memory = sum across selected tools
    disk   = sum across selected tools
  }
}
```

This is **not** a UI concept. It is Terraform logic that maps a *set* of tool
names to a single resource profile. It only runs when Terraform plans/applies,
not in the browser.

**Aggregation strategy** — chosen because IDEs running side by side share CPU
but each pulls its own RAM and install footprint:

| Resource | Strategy | Why |
| -------- | -------- | --- |
| CPU      | `max`    | IDEs schedule CPU in turn; the heaviest sets the baseline |
| Memory   | `sum`    | Each IDE keeps its own working set in RAM |
| Disk     | `sum`    | Install + caches stack on disk |

### 2. Dynamic Parameters — runs in the browser form

```hcl
data "coder_parameter" "cpu" {
  default = local.profile.cpu   # <-- the magic
  ...
}
```

When dynamic parameters is enabled, Coder re-evaluates the whole template
**in real time** as the user interacts with the form. Every time the `tools`
multi-select changes, Coder re-runs the parameter definitions, recomputes
`local.profile`, and updates the slider `default` values.

### 3. Presets — just set parameter values

```hcl
data "coder_workspace_preset" "fullstack" {
  name = "Full-stack (IntelliJ + VS Code)"
  parameters = {
    tools = jsonencode(["intellij", "vscode"])
  }
}
```

A preset is just a shortcut that injects parameter values into the form.
Because presets only set the `tools` list (not cpu/memory/disk directly),
the sliders stay editable and the user can still uncheck/check tools.

---

## Step-by-step: CPU change with multi-select

**Initial state — form loads, no preset, default empty selection:**
```
tools  = []
cpu    = 2     (length(selected) == 0 → fallback profile)
memory = 2
disk   = 2
```

**Step 1 — User ticks "IntelliJ" in the multi-select:**
```
tools = ["intellij"]
local.profile = { cpu = max(4)        = 4
                  memory = sum(6)     = 6
                  disk   = sum(10)    = 10 }
cpu    slider default → 4
memory slider default → 6
disk   slider default → 10
```
None of the sliders has been touched, so all three jump to the new defaults.

**Step 2 — User drags CPU slider to 6:**
```
tools = ["intellij"]
cpu  = 6   ← user-modified, now "owned" by the user
```
Coder marks `cpu` as user-modified. `memory` and `disk` are still untouched.

**Step 3 — User also ticks "VS Code":**
```
tools = ["intellij", "vscode"]
local.profile = { cpu = max(4, 2)    = 4
                  memory = 6 + 4     = 10
                  disk   = 10 + 5    = 15 }
cpu    slider → stays at 6   (user-modified, respected)
memory slider → updates to 10 (still untouched, follows default)
disk   slider → updates to 15 (still untouched, follows default)
```

**Step 4 — User selects the "Minimal (no IDE)" preset:**
```
preset injects → tools = []
local.profile = { cpu = 2, memory = 2, disk = 2 }
cpu    slider → stays at 6   (still user-modified)
memory slider → updates to 2
disk   slider → updates to 2
```

---

## The rule in one sentence

> **Presets and dynamic defaults only affect parameters the user has not
> touched. Once you move a slider, Coder considers that value "owned" by the
> user and stops overwriting it.**

---

## How to reset a user-modified value back to dynamic default

There is no "reset to default" button in the Coder UI today. The user must
either:

- Manually drag the slider back to match the computed profile (visible in the
  read-only **Computed profile** parameter at the top of the form), or
- Close and reopen the workspace creation form to start fresh.

This is by design — Coder assumes that if you touched a value, you meant to
override it.

---

## Why a multi-select instead of multiple presets?

Coder presets are **single-select** — you can apply one preset at a time,
and applying a new one replaces the previous selection. To let users combine
tools, the cleaner pattern is to make the *parameter* multi-select and use
presets as starter shortcuts ("Full-stack", "Everything") that pre-fill the
selection without locking it.
