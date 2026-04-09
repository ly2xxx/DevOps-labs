# Exercise 1: Create Your First Coder Task

## Objective
Learn the basics of creating and managing Coder Tasks.

## Prerequisites
- Coder CLI installed and configured
- Access to a Coder instance

## Steps

### 1. Check Available Templates
```bash
# List all available templates
coder templates list
```

### 2. Check Available Presets
```bash
# List presets (useful for task creation)
coder templates presets list -o json
```

### 3. Create a Simple Task
```bash
# Create a task that writes a hello world script
coder tasks create \
  --template ubuntu \
  --preset "" \
  "Create a Python script called hello.py that prints 'Hello from Coder Tasks!'"
```

### 4. Monitor the Task
```bash
# List all tasks to see yours
coder tasks list

# View the task output as it runs
coder tasks logs <task-name>
```

### 5. Connect to the Task (Optional)
```bash
# If the task is waiting for input or you want to interact
coder tasks connect <task-name>
```

### 6. Clean Up
```bash
# Delete the task when done
coder tasks delete <task-name> -y
```

## Expected Output

You should see:
1. A new task appear in `coder tasks list`
2. Output showing the Python script being created
3. The task completing successfully

## Troubleshooting

- **Template not found**: Choose a template from the list in step 1
- **Preset required**: If creation fails, try a specific preset from step 2
- **Permission denied**: Check your Coder authentication with `coder whoami`

## Bonus Challenge

Try creating a task that:
- Generates a simple web server
- Creates a README file
- Sets up a basic project structure

```bash
# Example bonus task
coder tasks create \
  --template node \
  --preset "default" \
  "Create a simple Node.js Express server with package.json, server.js, and README.md"
```