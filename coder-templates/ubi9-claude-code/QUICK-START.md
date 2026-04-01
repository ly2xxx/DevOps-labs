# Quick Start Guide - UBI9 Claude Code Template

**Get up and running in 5 minutes!**

---

## Prerequisites Check

```powershell
# Check Docker
docker version

# Check Coder CLI
coder version

# Check Coder server
coder ping
```

All green? Continue! ✅

---

## Setup (One-Time)

### Option 1: Automated (Recommended)

```powershell
cd C:\code\DevOps-labs\coder-templates\ubi9-claude-code
.\setup.ps1
```

This script will:
1. Build Docker image
2. Create Coder template
3. Show next steps

**Done in ~5 minutes!**

---

### Option 2: Manual

**Step 1: Build image**
```powershell
cd C:\code\DevOps-labs\docker-dx-extension\ubi9-minimal-coder
docker build -f Dockerfile.with-claude-code -t ubi9-minimal-coder:with-claude-code .
```

**Step 2: Create template**
```powershell
cd C:\code\DevOps-labs\coder-templates\ubi9-claude-code
coder templates create ubi9-claude-code --directory .
```

---

## Create Workspace

### Command Line:
```bash
coder create my-claude-workspace --template ubi9-claude-code
```

### Coder UI:
1. Open http://localhost:7080
2. Click "Create Workspace"
3. Select template: `ubi9-claude-code`
4. Configure (or use defaults):
   - CPU: 2 cores
   - Memory: 4 GB
5. Name: `my-claude-workspace`
6. Click "Create"

**Wait 30-60 seconds for workspace to start...**

---

## Access Workspace

### Terminal (SSH):
```bash
coder ssh my-claude-workspace
```

### VS Code:
```bash
code --folder-uri vscode-remote://coder+my-claude-workspace/home/coder/workspace
```

### Web Terminal:
Open Coder UI → Your workspace → "Terminal" button

---

## Configure Claude Code

**Inside the workspace:**

```bash
# Set API key (replace with your actual key)
export ANTHROPIC_API_KEY="sk-ant-..."

# Make it permanent
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
source ~/.bashrc

# Verify
claude-code --version
```

---

## Use Claude Code

```bash
# Interactive mode
claude-code

# With a task
claude-code "Create a Python Flask API"

# Help
claude-code --help
```

---

## Common Commands

```bash
# List workspaces
coder list

# Stop workspace (saves resources)
coder stop my-claude-workspace

# Start workspace
coder start my-claude-workspace

# SSH into workspace
coder ssh my-claude-workspace

# Delete workspace (keeps template)
coder delete my-claude-workspace

# Update workspace to latest template
coder update my-claude-workspace
```

---

## Troubleshooting

### Claude Code not found?
```bash
# Check installation
which claude-code
ls -la ~/.npm-global/bin/

# Reinstall
npm install -g @anthropic-ai/claude-code
```

### Workspace won't start?
```bash
# Check Docker
docker ps -a | grep coder

# Check logs
coder server logs

# Restart workspace
coder stop my-claude-workspace
coder start my-claude-workspace
```

### Can't connect?
```bash
# Test connection
coder ping my-claude-workspace

# Check agent status
coder list
```

---

## What's Included

**In the workspace:**
- ✅ Claude Code CLI
- ✅ Node.js & npm
- ✅ Persistent `/home/coder` directory
- ✅ Welcome README at `~/workspace/README.md`

**Tools you might want to add:**
```bash
# Git
sudo microdnf install -y git

# Python
sudo microdnf install -y python3

# Vim
sudo microdnf install -y vim
```

---

## File Locations

**Your projects:** `/home/coder/workspace`  
**Home dir:** `/home/coder` (persistent)  
**npm global:** `/home/coder/.npm-global`

---

## Next Steps

1. ✅ Create workspace
2. ✅ Configure Claude API key
3. 🚀 Start coding!

**For detailed docs:** See `README.md`

---

**That's it! Happy coding with Claude!** 🤖🚀
