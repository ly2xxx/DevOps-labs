# Coder Tasks Quick Reference

## Essential Commands

```bash
# Authentication
export CODER_URL=https://your-coder-instance.com
export CODER_SESSION_TOKEN=your_token
coder whoami

# Workspaces
coder list
coder create <name> --template <template>
coder start <name>
coder stop <name>
coder delete <name> -y
coder ssh <name> -- <command>
coder logs <name> -f

# Tasks
coder tasks create --template <template> --preset "<preset>" "prompt"
coder tasks list
coder tasks logs <task-name>
coder tasks connect <task-name>
coder tasks delete <task-name> -y
```

## Templates & Presets

```bash
# List available
coder templates list
coder templates presets list -o json
```

## Task Creation Flow

1. `coder templates list` → Get template name
2. `coder templates presets list -o json` → Get preset (if needed)
3. `coder tasks create --template <name> --preset "<preset>" "prompt"`
4. `coder tasks list` → Track status
5. `coder tasks logs <name>` → View output

## Status States

- **Initializing**: Workspace provisioning
- **Working**: Setup running
- **Active**: Agent processing
- **Idle**: Waiting for input