# How Dynamic Parameters, Presets, and Locals Work Together

## The Three Layers

### 1. `locals` — pure Terraform, runs server-side at plan time

```hcl
locals {
  tool_profiles = {
    none     = { cpu = 2, ... }
    intellij = { cpu = 4, ... }
  }
  profile = local.tool_profiles[data.coder_parameter.tool.value]
}
```

This is **not** a UI concept. It is Terraform logic that maps a tool name to
resource numbers. It only runs when Terraform plans/applies, not in the browser.

### 2. Dynamic Parameters — runs in the browser form

```hcl
data "coder_parameter" "cpu" {
  default = local.profile.cpu   # <-- this is the key
  ...
}
```

When dynamic parameters is enabled, Coder re-evaluates the whole template
**in real time** as the user interacts with the form. Every time a parameter
changes, Coder re-runs the parameter definitions and recalculates `default`.

### 3. Presets — just set parameter values

```hcl
data "coder_workspace_preset" "intellij" {
  parameters = {
    tool = "intellij"   # only sets tool
  }
}
```

A preset is just a shortcut that injects parameter values into the form —
nothing more.

---

## Step-by-step: CPU change when switching preset

**Initial state — form loads:**
```
tool = "none"   (default)
cpu  = 2        (default = local.profile.cpu → tool_profiles["none"].cpu = 2)
```

**Step 1 — User manually drags CPU slider to 6:**
```
tool = "none"
cpu  = 6   ← user has now "touched" this field
```
The form marks `cpu` as **user-modified**. Coder tracks which parameters the
user has explicitly set vs which are still at their computed default.

**Step 2 — User selects "IntelliJ IDEA" preset:**
```
preset injects → tool = "intellij"
```
Coder re-evaluates the template with `tool = "intellij"`.
`local.profile.cpu` now resolves to `4`.
`default = local.profile.cpu` → new default is `4`.

But here is the split:
- `cpu` was **user-modified** → Coder keeps `6` (respects user intent)
- If `cpu` had not been touched → Coder would update it to `4`

**Step 3 — User selects "Minimal" preset:**
```
preset injects → tool = "none"
```
`local.profile.cpu` → `2`.
`cpu` is still user-modified → stays at `6`.

---

## The rule in one sentence

> **Presets and dynamic defaults only affect parameters the user has not
> touched. Once you move a slider, Coder considers that value "owned" by the
> user and stops overwriting it.**

---

## How to reset a user-modified value back to dynamic default

There is currently no "reset to default" button in the Coder UI. The user
must either:

- Manually slide the slider back to match what the tool profile says
- Or start fresh (close and reopen the creation form)

This is by design — Coder assumes that if you touched a value, you meant to
override it.
