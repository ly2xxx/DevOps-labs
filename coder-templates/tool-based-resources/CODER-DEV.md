# Coder Template Developer Guide: Tool-Based Resources

This guide explains the "nits and grits" of how this template uses **Dynamic Parameters** and **Docker Resources** to create a smart, reactive workspace.

## 1. Dynamic Parameter Architecture

The template uses a "Parent-Child" parameter relationship.

### The Driver: `tools` Parameter
- **Type**: `multi-select` (returns a JSON-encoded list of strings).
- **Function**: Acts as the primary input for the user.
- **Logic**: Located in `locals {}`, where we decode the selection and calculate a resource profile.
    - **CPU**: Uses `max()` across selected tools (IDEs share CPU).
    - **RAM/Disk**: Uses `sum()` (each tool needs its own footprint).

### The Dynamic Children: `cpu`, `memory`, `disk`
- **Dynamic Defaults**: These parameters use `default = local.profile.cpu`. 
- **Reactive UI**: When a user selects "IntelliJ" in the UI, the CPU slider automatically moves to `4`. If they uncheck it, it moves back to `2`.
- **Overrides**: Users can still manually move the sliders to override the "smart" defaults.

### Dynamic Validation (Guardrails)
- **Tool-Driven Constraints**: The `tools` parameter dynamically affects the `min` validation limits of the `cpu`, `memory`, and `disk` parameters.
    - Setting `min = local.profile.cpu` ensures that a user cannot provision a workspace with fewer resources than their selected tools demand.
    - Because the default matches the minimum, if a user tries to manually override the slider with a value below the calculated baseline, the Coder UI will automatically throw a red validation error.


---

## 2. Infrastructure Resources

### Storage: `docker_volume`
- **Persistence**: Uses `lifecycle { ignore_changes = all }`.
- **Why?**: Coder workspaces are ephemeral (the container is deleted when stopped). The volume must stay independent so user files in `/home/coder` persist across restarts.
- **Provider**: `kreuzwerker/docker`

### The Brain: `coder_agent`
- **The Heart of Coder**: This binary runs inside the container and communicates with the Coder server.
- **`startup_script`**: Runs on boot. It uses the Terraform-calculated list of tools to run installation commands.
- **`display_apps`**: Controls which buttons (VS Code, Terminal) appear in the Coder dashboard.
- **`metadata`**: Defines the live stats (CPU/RAM usage) displayed in the UI.
- **Provider**: `coder/coder`

### The Compute: `docker_container`
- **Start/Stop Logic**: `count = data.coder_workspace.me.start_count`.
    - `0` = Workspace stopped (Container deleted).
    - `1` = Workspace started (Container created).
- **Resource Enforcement**: This is where the parameters are actually applied to the Docker engine via `cpu_shares`, `memory`, and `storage_opts`.

---

## 3. Developer Resources & Documentation

### Where to look things up:
- **Docker Provider Docs**: [Terraform Registry - Docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
    - Check here for container options like `networks`, `capabilities`, or `env`.
- **Coder Provider Docs**: [Terraform Registry - Coder](https://registry.terraform.io/providers/coder/coder/latest/docs)
    - Check here for `coder_agent`, `coder_parameter`, and `coder_app`.
- **Coder Official Guides**: [coder.com/docs](https://coder.com/docs)
    - Best for architectural patterns and "Dynamic Parameters" examples.

### Pro-Tip for Debugging:
If your startup script fails, check the **Agent Logs** in the Coder UI. Any `echo` commands in your `startup_script` will appear there in real-time.
