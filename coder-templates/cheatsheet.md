# Coder CLI Cheat Sheet

Quick reference for Coder CLI commands, workspace management, templates, and task automation.

---

## 🔑 Authentication

```bash
# Set Coder instance URL
export CODER_URL=https://your-coder-instance.com
# Or in PowerShell: $env:CODER_URL="https://your-coder-instance.com"

# Log in using web browser token
coder login $CODER_URL

# Check current active session details
coder whoami
```

---

## 💻 Workspace Management

```bash
# List all workspaces
coder list

# Create a workspace
coder create <workspace-name> --template <template-name>

# Start a workspace
coder start <workspace-name>

# Stop a workspace
coder stop <workspace-name>

# Delete a workspace (with auto-approve confirmation)
coder delete <workspace-name> -y

# View resource usage stats inside the workspace
coder stat <workspace-name>
```

---

## 🛡️ SSH & File Operations

```bash
# Connect to workspace via SSH
coder ssh <workspace-name>

# Run a specific command over SSH directly
coder ssh <workspace-name> -- "pip install MCP-server"

# View agent logs from a workspace
coder logs <workspace-name> -f
```

---

## 📦 Templates & Custom Parameters

```bash
# List all templates available on the server
coder templates list

# Create or push a new template version
coder templates push <template-name> --directory ./my-template-dir

# View template parameter configurations
coder templates init
```

---

## 🤖 Tasks & Presets

```bash
# List all active background tasks
coder tasks list

# Create a task based on a template and preset
coder tasks create --template <template-name> --preset "<preset-name>" "Task description prompt"

# Stream logs for a running task
coder tasks logs <task-name>

# Attach/Connect to a task's interactive session
coder tasks connect <task-name>

# Cancel/Delete a task
coder tasks delete <task-name> -y
```

---

## 📊 Presets & Status States

### Preset Command Flow
1. Check templates: `coder templates list`
2. Extract presets: `coder templates presets list -o json`
3. Launch task: `coder tasks create --template <template> --preset "<preset>" "<prompt>"`

### Task Status Lifecycle
- **Initializing**: Workspace provisioning is occurring.
- **Working**: Setup scripts or startup files are running.
- **Active**: Agent is currently executing the task.
- **Idle**: Task completed, waiting for next instruction or shutdown.
