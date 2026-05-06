terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.3.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

variable "image" {
  description = "Docker image to use for the workspace"
  default     = "codercom/enterprise-base:ubuntu"
  type        = string
}

# ------------------------------------------------------------------
# Tool selection drives resource defaults
# ------------------------------------------------------------------
data "coder_parameter" "tool" {
  name         = "tool"
  display_name = "Primary Tool / IDE"
  description  = "Selecting a heavier IDE bumps CPU / RAM / DISK defaults."
  type         = "string"
  default      = "none"
  mutable      = true
  order        = 1

  option {
    name        = "None (lightweight shell)"
    value       = "none"
    description = "2 CPU, 2 GB RAM, 2 GB disk"
  }
  option {
    name        = "IntelliJ IDEA"
    value       = "intellij"
    description = "4 CPU, 6 GB RAM, 10 GB disk"
  }
  option {
    name        = "VS Code"
    value       = "vscode"
    description = "2 CPU, 4 GB RAM, 5 GB disk"
  }
}

locals {
  tool_profiles = {
    none     = { cpu = 2, memory = 2, disk = 2 }
    intellij = { cpu = 4, memory = 6, disk = 10 }
    vscode   = { cpu = 2, memory = 4, disk = 5 }
  }
  profile = local.tool_profiles[data.coder_parameter.tool.value]
}

# ------------------------------------------------------------------
# Dynamic parameters: defaults reference the tool selection above.
# Users can still override; if they don't, the tool profile wins.
# Requires Coder >= 2.19 (dynamic parameters are GA).
# ------------------------------------------------------------------
data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU Cores"
  description  = "Override CPU cores (default comes from tool selection)."
  type         = "number"
  form_type    = "slider"
  default      = local.profile.cpu
  mutable      = true
  order        = 2
  validation {
    min = 1
    max = 16
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Override RAM (default comes from tool selection)."
  type         = "number"
  form_type    = "slider"
  default      = local.profile.memory
  mutable      = true
  order        = 3
  validation {
    min = 1
    max = 64
  }
}

data "coder_parameter" "disk" {
  name         = "disk"
  display_name = "Disk (GB)"
  description  = "Override disk (default comes from tool selection)."
  type         = "number"
  form_type    = "slider"
  default      = local.profile.disk
  mutable      = false # disk is set at create time only
  order        = 4
  validation {
    min = 1
    max = 200
  }
}

# ------------------------------------------------------------------
# Optional: presets bundle a tool + matching resources as one click.
# ------------------------------------------------------------------
data "coder_workspace_preset" "intellij" {
  name = "IntelliJ (4 CPU / 6 GB / 10 GB)"
  parameters = {
    (data.coder_parameter.tool.name)   = "intellij"
    (data.coder_parameter.cpu.name)    = "4"
    (data.coder_parameter.memory.name) = "6"
    (data.coder_parameter.disk.name)   = "10"
  }
}

data "coder_workspace_preset" "vscode" {
  name = "VS Code (2 CPU / 4 GB / 5 GB)"
  parameters = {
    (data.coder_parameter.tool.name)   = "vscode"
    (data.coder_parameter.cpu.name)    = "2"
    (data.coder_parameter.memory.name) = "4"
    (data.coder_parameter.disk.name)   = "5"
  }
}

data "coder_workspace_preset" "minimal" {
  name = "Minimal (2 CPU / 2 GB / 2 GB)"
  parameters = {
    (data.coder_parameter.tool.name)   = "none"
    (data.coder_parameter.cpu.name)    = "2"
    (data.coder_parameter.memory.name) = "2"
    (data.coder_parameter.disk.name)   = "2"
  }
}

# ------------------------------------------------------------------
# Workspace plumbing
# ------------------------------------------------------------------
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "coder_provisioner" "me" {}

provider "docker" {}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  lifecycle {
    ignore_changes = all
  }
}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = data.coder_provisioner.me.arch
  startup_script = <<-EOT
    set -e
    echo "🛠  Tool selected: ${data.coder_parameter.tool.value}"
    echo "💻 CPU:    ${data.coder_parameter.cpu.value} cores"
    echo "🧠 Memory: ${data.coder_parameter.memory.value} GB"
    echo "💾 Disk:   ${data.coder_parameter.disk.value} GB (volume size hint)"

    case "${data.coder_parameter.tool.value}" in
      intellij)
        echo "Installing IntelliJ Community (Projector/JetBrains Gateway-ready)…"
        # Replace with your real installer / pre-baked image
        ;;
      vscode)
        echo "VS Code will be available via the web IDE (code-server) display app."
        ;;
      none)
        echo "Lightweight shell — no IDE bootstrapped."
        ;;
    esac
  EOT

  display_apps {
    vscode       = data.coder_parameter.tool.value == "vscode"
    web_terminal = true
    ssh_helper   = true
  }

  metadata {
    display_name = "Tool"
    key          = "tool"
    script       = "echo ${data.coder_parameter.tool.value}"
    interval     = 0
    timeout      = 1
  }
  metadata {
    display_name = "CPU Usage"
    key          = "cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Memory Usage"
    key          = "mem_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = var.image
  name  = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]

  # Resource limits driven by tool selection (or user override)
  cpu_shares  = data.coder_parameter.cpu.value * 1024
  memory      = data.coder_parameter.memory.value * 1024 # MB
  # Note: storage_opts size is only enforced on overlay2 + xfs (with pquota)
  # or btrfs. On Docker Desktop (Windows/Mac) this is accepted but advisory.
  storage_opts = {
    size = "${data.coder_parameter.disk.value}G"
  }

  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
  }

  command  = ["sh", "-c", coder_agent.main.init_script]
  hostname = data.coder_workspace.me.name

  labels {
    label = "coder.tool_profile"
    value = data.coder_parameter.tool.value
  }
}

output "selected_profile" {
  value = {
    tool   = data.coder_parameter.tool.value
    cpu    = data.coder_parameter.cpu.value
    memory = data.coder_parameter.memory.value
    disk   = data.coder_parameter.disk.value
  }
}
