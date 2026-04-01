# UBI9 Claude Code Workspace Template

**Coder template for local development with Claude Code CLI pre-installed**

---

## Overview

This template creates a workspace using the UBI9-minimal image with Claude Code CLI pre-installed.

**Includes:**
- ✅ Red Hat UBI9 minimal base
- ✅ Claude Code CLI (Node.js-based)
- ✅ npm & Node.js
- ✅ Persistent home directory
- ✅ VS Code web support
- ✅ SSH access

---

## Prerequisites

1. **Coder server running locally**
   ```bash
   # Check if Coder is running
   coder version
   ```

2. **Docker image built**
   ```bash
   cd C:\code\DevOps-labs\docker-dx-extension\ubi9-minimal-coder
   docker build -f Dockerfile.with-claude-code -t ubi9-minimal-coder:with-claude-code .
   ```

3. **Verify image**
   ```bash
   docker images | grep ubi9-minimal-coder
   ```

---

## Installation

### Step 1: Create Template in Coder

**Option A: Using Coder CLI**

```bash
# Navigate to template directory
cd C:\code\DevOps-labs\coder-templates\ubi9-claude-code

# Create/update template
coder templates create ubi9-claude-code --directory .

# Or update if already exists
coder templates push ubi9-claude-code --directory .
```

**Option B: Using Coder UI**

1. Open Coder UI: http://localhost:7080 (or your Coder URL)
2. Go to Templates
3. Click "Create Template"
4. Upload `main.tf` file
5. Name: `ubi9-claude-code`
6. Click "Create"

---

### Step 2: Create Workspace

**Using Coder UI:**

1. Go to Workspaces
2. Click "Create Workspace"
3. Select template: `ubi9-claude-code`
4. Configure parameters:
   - **CPU**: 2 cores (default)
   - **Memory**: 4 GB (default)
   - **Dotfiles URI**: (optional)
5. Name your workspace: e.g., `my-claude-workspace`
6. Click "Create Workspace"

**Using Coder CLI:**

```bash
coder create my-claude-workspace --template ubi9-claude-code
```

---

### Step 3: Access Workspace

**Terminal:**
```bash
coder ssh my-claude-workspace
```

**VS Code:**
```bash
code --folder-uri vscode-remote://coder+my-claude-workspace/home/coder/workspace
```

**Web Terminal:**
Open Coder UI → Your workspace → "Terminal" button

---

## Using Claude Code in the Workspace

### 1. SSH into workspace

```bash
coder ssh my-claude-workspace
```

### 2. Set up API key

```bash
# Set environment variable
export ANTHROPIC_API_KEY="your-api-key-here"

# Or create .env file (recommended for persistence)
echo "ANTHROPIC_API_KEY=your-key" > ~/.env
echo "ANTHROPIC_API_KEY=your-key" >> ~/.bashrc  # Load on shell start
source ~/.bashrc
```

### 3. Run Claude Code

```bash
# Interactive mode
claude-code

# With a task
claude-code "Create a Python Flask API with health check endpoint"

# Check version
claude-code --version
```

### 4. Verify installation

```bash
# Check Claude Code
which claude-code
claude-code --version

# Check Node.js
node --version

# Check npm
npm --version
```

---

## Template Features

### Configurable Parameters

| Parameter | Options | Default | Description |
|-----------|---------|---------|-------------|
| **CPU** | 1, 2, 4 cores | 2 | CPU allocation |
| **Memory** | 2, 4, 8 GB | 4 GB | Memory allocation |
| **Dotfiles URI** | Git URL | - | Optional dotfiles repo |

### Persistent Storage

- **Home directory**: `/home/coder` (persisted across restarts)
- **Workspace**: `/home/coder/workspace` (recommended for projects)

All files in `/home/coder` are preserved when you stop/start the workspace!

### Built-in Apps

- ✅ VS Code Web
- ✅ Web Terminal
- ✅ SSH Access
- ✅ Port Forwarding

### Monitoring

The workspace reports:
- CPU usage
- Memory usage
- Disk usage
- Claude Code version

View in Coder UI under workspace details.

---

## Customization

### Add More Tools

Edit `main.tf` and add to `startup_script`:

```hcl
startup_script = <<-EOT
  # ... existing script ...

  # Install git
  sudo microdnf install -y git

  # Install Python
  sudo microdnf install -y python3 python3-pip

  # Install vim
  sudo microdnf install -y vim
EOT
```

### Change Default Image

Edit `main.tf`:

```hcl
variable "image" {
  default = "your-custom-image:tag"
}
```

### Adjust Resource Limits

In Coder UI when creating workspace, or edit template defaults in `main.tf`.

---

## Troubleshooting

### Issue 1: Claude Code not found

**Check installation:**
```bash
coder ssh my-claude-workspace
which claude-code
ls -la ~/.npm-global/bin/
```

**Reinstall:**
```bash
npm install -g @anthropic-ai/claude-code
```

### Issue 2: Permission denied

**Verify user:**
```bash
whoami  # Should be "coder"
id      # Should show uid=1000
```

**Fix npm permissions:**
```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
```

### Issue 3: Docker image not found

**Build image:**
```bash
cd C:\code\DevOps-labs\docker-dx-extension\ubi9-minimal-coder
docker build -f Dockerfile.with-claude-code -t ubi9-minimal-coder:with-claude-code .
```

**Verify:**
```bash
docker images | grep ubi9-minimal-coder
```

### Issue 4: Workspace won't start

**Check Coder logs:**
```bash
coder server logs
```

**Check Docker:**
```bash
docker ps -a | grep coder
docker logs <container-id>
```

### Issue 5: Can't connect to workspace

**Check agent status:**
```bash
coder ping my-claude-workspace
```

**Restart workspace:**
```bash
coder stop my-claude-workspace
coder start my-claude-workspace
```

---

## Advanced Usage

### Using with VS Code Remote

1. Install "Remote - SSH" extension in VS Code
2. Connect via Coder:
   ```bash
   code --folder-uri vscode-remote://coder+my-claude-workspace/home/coder/workspace
   ```

### Port Forwarding

Forward ports from workspace to local machine:

```bash
# Forward port 8080
coder port-forward my-claude-workspace --tcp 8080:8080
```

### Dotfiles Integration

Pass a dotfiles repo when creating workspace:

```bash
coder create my-workspace \
  --template ubi9-claude-code \
  --parameter dotfiles_uri=https://github.com/yourusername/dotfiles
```

The template will:
1. Clone the repo to `~/dotfiles`
2. Run `~/dotfiles/install.sh` if it exists

---

## Template Update Workflow

### Update Template

1. Edit `main.tf`
2. Push changes:
   ```bash
   coder templates push ubi9-claude-code --directory .
   ```

### Update Existing Workspaces

```bash
# Update workspace to latest template version
coder update my-claude-workspace
```

---

## Template Files

```
C:\code\DevOps-labs\coder-templates\ubi9-claude-code\
├── main.tf              # Terraform template (Coder + Docker providers)
├── README.md            # This file
└── .terraform.lock.hcl  # (Generated after first apply)
```

---

## Quick Reference

### Common Commands

```bash
# Create workspace
coder create my-workspace --template ubi9-claude-code

# SSH into workspace
coder ssh my-workspace

# Stop workspace
coder stop my-workspace

# Start workspace
coder start my-workspace

# Delete workspace (keeps template)
coder delete my-workspace

# Update workspace to latest template
coder update my-workspace

# List workspaces
coder list

# List templates
coder templates list
```

### Template Management

```bash
# Create template
coder templates create ubi9-claude-code --directory .

# Update template
coder templates push ubi9-claude-code --directory .

# List templates
coder templates list

# Delete template
coder templates delete ubi9-claude-code
```

---

## Next Steps

1. ✅ Build Docker image
2. ✅ Create Coder template
3. ✅ Create workspace
4. 🚀 Start coding with Claude!

**Optional:**
- Add more tools to the image (git, python, etc.)
- Customize startup script
- Add pre-installed VS Code extensions
- Set up team templates for consistent environments

---

## Resources

- **Coder Docs**: https://coder.com/docs
- **Claude Code**: https://www.anthropic.com/
- **Docker Provider**: https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
- **UBI9 Docs**: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9

---

**Created**: April 1, 2026  
**Template Version**: 1.0  
**Docker Image**: `ubi9-minimal-coder:with-claude-code`  
**Coder Version**: Compatible with Coder v2.x

---

**Happy coding with Claude in Coder!** 🤖🚀
