# OpenClaw Coder Tasks Lab

## Overview

This lab explores how Coder Tasks work in OpenClaw, allowing you to run AI coding agents (Claude Code, Aider, Codex, etc.) in isolated workspaces.

## What are Coder Tasks?

Coder Tasks is a feature that runs AI agents in isolated, governed workspaces rather than on the host system directly. This provides:

- **Isolation**: Each task runs in its own workspace
- **Safety**: Tasks can't access your host system directly
- **Management**: Start, stop, monitor, and delete tasks easily
- **Flexibility**: Support for multiple AI coding agents

## Prerequisites

1. **Install Coder CLI**:
   ```bash
   # Follow: https://coder.com/docs/install/cli
   npm install -g coder
   ```

2. **Configure Authentication**:
   ```bash
   export CODER_URL=https://your-coder-instance.com
   export CODER_SESSION_TOKEN= # Get from /cli-auth
   ```

3. **Test Connection**:
   ```bash
   coder whoami
   ```

## Basic Commands

### Workspace Management
```bash
# List all workspaces
coder list
coder list --all
coder list -o json

# Workspace operations
coder start <workspace>
coder stop <workspace>
coder restart <workspace> -y
coder delete <workspace> -y

# Access workspaces
coder ssh <workspace>              # Interactive shell
coder ssh <workspace> -- <command> # Run command
coder logs <workspace>
coder logs <workspace> -f          # Follow logs
```

### Coder Tasks Management
```bash
# Create a task
coder tasks create --template <template> --preset "<preset>" "Your prompt here"

# List all tasks
coder tasks list

# View task output
coder tasks logs <task-name>

# Connect to task (interactive)
coder tasks connect <task-name>

# Delete task
coder tasks delete <task-name> -y
```

## Task States

- **Initializing**: Workspace provisioning (timing varies by template)
- **Working**: Setup script running
- **Active**: Agent processing prompt
- **Idle**: Agent waiting for input

## Templates

List available templates:
```bash
coder templates list
```

## Presets

Get available presets:
```bash
coder templates presets list -o json
```

## Examples in This Lab

### 1. Quick One-Shot Task
```bash
# Create a simple task
coder tasks create --template ubuntu --preset "" "Write a Python hello world script"

# Check its status
coder tasks list

# View output
coder tasks logs <task-name>
```

### 2. Development Task
```bash
# Create a development task with a specific preset
coder tasks create --template node --preset "default" "Build a simple Express.js API server"

# Connect interactively
coder tasks connect <task-name>
```

### 3. Background Processing
```bash
# Create task that runs in background
coder tasks create --template python --preset "default" "Analyze this codebase and generate documentation"
```

## Integration with OpenClaw

OpenClaw can orchestrate Coder Tasks using the `coder-workspaces` skill:

```bash
# From OpenClaw
coder list
coder start my-workspace
coder tasks create --template node --preset "default" "Build a web app"
```

## Use Cases

1. **Code Review**: Isolated environments for reviewing PRs
2. **Feature Development**: Build new features in sandboxed workspaces
3. **Refactoring**: Large-scale refactoring with isolation
4. **Testing**: Run tests in isolated environments
5. ** prototyping**: Quick prototypes without cluttering main system

## Best Practices

1. **Always use templates**: Don't run without proper workspace isolation
2. **Monitor tasks**: Use `coder tasks list` to track running tasks
3. **Clean up**: Delete completed tasks with `coder tasks delete`
4. **Use appropriate presets**: Match preset to task requirements
5. **Check logs**: Monitor `coder tasks logs` for debugging

## Troubleshooting

### Common Issues

- **CLI not found**: Install from https://coder.com/docs/install/cli
- **Auth failed**: Verify CODER_URL and CODER_SESSION_TOKEN, run `coder login`
- **Version mismatch**: Reinstall CLI from your Coder instance
- **Template not found**: Check available templates with `coder templates list`

### Debug Tips

1. Always check `coder whoami` first
2. Use `-o json` flag for programmatic output
3. Monitor logs with `coder logs -f`
4. Check task status with `coder tasks list`

## Next Steps

Try the exercises in the `exercises/` directory to get hands-on experience with Coder Tasks!

## Resources

- [Coder Docs](https://coder.com/docs)
- [Coder CLI](https://coder.com/docs/install/cli)
- [Coder Tasks](https://coder.com/docs/ai-coder)
- [Coder Task Deep Dive](https://coder.com/docs/@v2.30.1/ai-coder/tasks)
- [OpenClaw Coder Workspaces Skill](https://github.com/openclaw/skills/blob/main/skills/developmentcats/coder-workspaces/SKILL.md)