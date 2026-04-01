terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

# Admin parameters
variable "image" {
  description = "Docker image to use"
  default     = "ubi9-minimal-coder:with-claude-code"
  type        = string
}

# User parameters
data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU Cores"
  description  = "Number of CPU cores"
  default      = "2"
  type         = "number"
  mutable      = true
  option {
    name  = "1 Core"
    value = "1"
  }
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Memory allocation in GB"
  default      = "4"
  type         = "number"
  mutable      = true
  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
}

data "coder_parameter" "dotfiles_uri" {
  name         = "dotfiles_uri"
  display_name = "Dotfiles URI (optional)"
  description  = "Git URL for dotfiles repository"
  default      = ""
  type         = "string"
  mutable      = true
}

# Workspace metadata
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# Docker provider
provider "docker" {}

data "coder_provisioner" "me" {}

# Docker network for the workspace
resource "docker_network" "private_network" {
  name = "coder-${data.coder_workspace.me.id}"
}

# Persistent volume for workspace data
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Lifecycle rules
  lifecycle {
    ignore_changes = all
  }
}

# Coder agent
resource "coder_agent" "main" {
  os                     = "linux"
  arch                   = data.coder_provisioner.me.arch
  startup_script         = <<-EOT
    set -e

    # claude-code is installed system-wide as root (/usr/local/bin) — no PATH setup needed

    # Install dotfiles if provided
    if [ -n "${data.coder_parameter.dotfiles_uri.value}" ]; then
      echo "📦 Installing dotfiles from ${data.coder_parameter.dotfiles_uri.value}..."
      if command -v git > /dev/null 2>&1; then
        git clone "${data.coder_parameter.dotfiles_uri.value}" ~/dotfiles
        if [ -f ~/dotfiles/install.sh ]; then
          bash ~/dotfiles/install.sh
        fi
      else
        echo "⚠️  Git not available, skipping dotfiles"
      fi
    fi

    # Verify Claude Code installation (system-wide install at /usr/local/bin/claude-code)
    echo "🤖 Verifying Claude Code installation..."
    if command -v claude-code > /dev/null 2>&1; then
      echo "✅ Claude Code version: $(claude-code --version 2>&1 | head -1)"
    else
      echo "⚠️  claude-code not found in PATH — workspace may be incomplete"
      echo "     PATH=$PATH"
      echo "     which node: $(which node 2>&1)"
    fi

    # Set up workspace
    mkdir -p ~/workspace
    cd ~/workspace

    # Create welcome message
    cat > ~/workspace/README.md <<'EOF'
# Welcome to Your Claude Code Workspace! 🤖

This workspace comes pre-configured with:
- ✅ Claude Code CLI
- ✅ Node.js & npm
- ✅ UBI9 minimal base (Red Hat Enterprise Linux)

## Quick Start

### 1. Configure Claude Code API Key

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

Or create a `.env` file:
```bash
echo "ANTHROPIC_API_KEY=your-key" > ~/.env
```

### 2. Start Claude Code

```bash
# Interactive mode
claude-code

# With a specific task
claude-code "Create a Python web server"

# Help
claude-code --help
```

### 3. Workspace Directory

Your persistent workspace is at: `~/workspace`

All files here are preserved across workspace restarts!

## Additional Tools

Install more tools as needed:
```bash
# Git (if not already installed)
microdnf install -y git

# Python
microdnf install -y python3

# Vim
microdnf install -y vim
```

## Useful Commands

- `claude-code --version` - Check Claude Code version
- `npm list -g` - List globally installed npm packages
- `node --version` - Check Node.js version

---

**Happy coding with Claude!** 🚀
EOF

    echo "✅ Workspace ready!"
  EOT

  # Metadata
  display_apps {
    vscode                 = true
    vscode_insiders        = false
    web_terminal           = true
    port_forwarding_helper = true
    ssh_helper             = true
  }

  metadata {
    display_name = "CPU Usage"
    key          = "cpu"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage"
    key          = "memory"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk Usage"
    key          = "disk"
    script       = "df -h /home/coder | awk 'NR==2 {print $5}'"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "Claude Code Version"
    key          = "claude_version"
    script       = "claude-code --version || echo 'Not installed'"
    interval     = 0  # Only run once
    timeout      = 5
  }
}

# Main container
resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = var.image
  name  = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"

  # Coder agent token
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]

  # Resource limits
  cpu_shares = tonumber(data.coder_parameter.cpu.value) * 1024
  memory     = tonumber(data.coder_parameter.memory.value) * 1024

  # Network
  networks_advanced {
    name = docker_network.private_network.name
  }

  # Volumes
  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
  }

  # Keep container running
  command = ["sh", "-c", coder_agent.main.init_script]

  # Hostname
  hostname = data.coder_workspace.me.name

  # Labels
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}

# Outputs
output "agent_token" {
  value     = coder_agent.main.token
  sensitive = true
}
