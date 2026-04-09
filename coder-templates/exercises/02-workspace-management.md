# Exercise 2: Workspace Management

## Objective
Learn how to manage Coder workspaces and run tasks within them.

## Prerequisites
- Completed Exercise 1
- Understanding of basic Coder commands

## Steps

### 1. Create a Dedicated Workspace
```bash
# Create a workspace for development work
coder create dev-lab --template node
```

### 2. List Workspaces
```bash
# See all workspaces
coder list
coder list --all
```

### 3. Start the Workspace
```bash
# Start your new workspace
coder start dev-lab
```

### 4. SSH into the Workspace
```bash
# Interactive shell
coder ssh dev-lab

# Or run a command directly
coder ssh dev-lab -- pwd
coder ssh dev-lab -- ls -la
```

### 5. Create a Task in the Workspace
```bash
# From your host terminal, create a task
coder tasks create \
  --workspace dev-lab \
  --preset "default" \
  "Set up a basic Express.js application with routes for GET /api/users and POST /api/users"
```

### 6. Monitor Workspace Logs
```bash
# See workspace activity
coder logs dev-lab
coder logs dev-lab -f  # Follow logs
```

### 7. Check Task Progress
```bash
# List tasks (should show your new task)
coder tasks list

# View task output
coder tasks logs <task-name>
```

### 8. Stop and Clean Up
```bash
# Stop the workspace
coder stop dev-lab

# Delete when done
coder delete dev-lab -y
```

## Expected Output

You should see:
1. A new workspace created with Node.js template
2. Ability to SSH and run commands in the workspace
3. Task running within the specific workspace
4. Clean separation between workspace and task

## Advanced: Multiple Workspaces

Try creating multiple workspaces for different purposes:

```bash
# Frontend workspace
coder create frontend --template react

# Backend workspace  
coder create backend --template node

# Database workspace
coder create database --template postgres

# Start them all
coder start frontend
coder start backend
coder start database
```

## Workspace Templates

Common templates you might use:
- `ubuntu` - Basic Linux environment
- `node` - Node.js development
- `python` - Python development
- `react` - React frontend
- `postgres` - PostgreSQL database
- `docker` - Docker container management

## Best Practices

1. **Name workspaces meaningfully**: Use descriptive names
2. **Use appropriate templates**: Match template to task needs
3. **Monitor resources**: Check `coder list` for running workspaces
4. **Clean up**: Delete unused workspaces to save resources

## Troubleshooting

- **Workspace won't start**: Check template availability and resources
- **SSH fails**: Ensure workspace is running first
- **Task creation fails**: Verify workspace exists and is running

## Integration with OpenClaw

In OpenClaw, you can automate this workflow:

```bash
# From OpenClaw (using coder-workspaces skill)
coder create my-project --template node
coder start my-project
coder ssh my-project -- npm init -y
coder tasks create --workspace my-project --preset "default" "Build a REST API"
```