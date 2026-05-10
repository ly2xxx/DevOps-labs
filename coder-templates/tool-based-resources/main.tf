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
# Multi-select tool picker — drives resource defaults via locals
# ------------------------------------------------------------------
data "coder_parameter" "tools" {
  name         = "tools"
  display_name = "Tools / IDEs to install"
  description  = "Pick one or more. Resource defaults adjust to fit the combined selection (max CPU, summed RAM/disk)."
  type         = "list(string)"
  form_type    = "multi-select"
  default      = jsonencode([])
  mutable      = true
  order        = 1

  option {
    name        = "IntelliJ IDEA"
    value       = "intellij"
    description = "4 CPU baseline, 6 GB RAM, 10 GB disk"
    icon        = "/icon/intellij.svg"
  }
  option {
    name        = "VS Code"
    value       = "vscode"
    description = "2 CPU baseline, 4 GB RAM, 5 GB disk"
    icon        = "/icon/code.svg"
  }
  option {
    name        = "Cursor"
    value       = "cursor"
    description = "2 CPU baseline, 4 GB RAM, 5 GB disk"
    icon        = "/icon/cursor.svg"
  }
}

locals {
  tool_profiles = {
    intellij = { cpu = 4, memory = 6, disk = 10 }
    vscode   = { cpu = 2, memory = 4, disk = 5 }
    cursor   = { cpu = 2, memory = 4, disk = 5 }
  }

  selected = jsondecode(data.coder_parameter.tools.value)

  # Aggregation strategy:
  #   cpu    = max across selected tools (IDEs share CPU; heaviest sets baseline)
  #   memory = sum across selected tools (each IDE keeps its own working set in RAM)
  #   disk   = sum across selected tools (install footprints stack)
  # Empty selection falls back to a 2/2/2 minimal profile.
  profile = {
    cpu    = length(local.selected) == 0 ? 2 : max(2, max([for t in local.selected : local.tool_profiles[t].cpu]...))
    memory = length(local.selected) == 0 ? 2 : sum([for t in local.selected : local.tool_profiles[t].memory])
    disk   = length(local.selected) == 0 ? 2 : sum([for t in local.selected : local.tool_profiles[t].disk])
  }
}

# ------------------------------------------------------------------
# Read-only summary so the user can see the derivation in the form
# ------------------------------------------------------------------
data "coder_parameter" "summary" {
  name         = "summary"
  display_name = "Computed profile"
  description  = <<-EOT
    Selected tools: ${length(local.selected) == 0 ? "(none)" : join(", ", local.selected)}

    Defaults → CPU **${local.profile.cpu}** · RAM **${local.profile.memory} GB** · Disk **${local.profile.disk} GB**

  EOT
}

# ------------------------------------------------------------------
# Dynamic parameters: defaults reference the tool selection above.
# Users can still override; if they don't, the computed profile wins.
# Requires Coder >= 2.19 (dynamic parameters are GA).
# ------------------------------------------------------------------
data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU Cores"
  description  = "Override CPU cores. Cannot be lower than selected tools baseline."
  type         = "number"
  form_type    = "slider"
  default      = local.profile.cpu
  mutable      = true
  order        = 3
  validation {
    min = local.profile.cpu
    max = 16
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Override RAM. Cannot be lower than selected tools baseline."
  type         = "number"
  form_type    = "slider"
  default      = local.profile.memory
  mutable      = true
  order        = 4
  validation {
    min = local.profile.memory
    max = 64
  }
}

data "coder_parameter" "disk" {
  name         = "disk"
  display_name = "Disk (GB)"
  description  = "Override disk. Cannot be lower than selected tools baseline."
  type         = "number"
  form_type    = "slider"
  default      = local.profile.disk
  mutable      = false # disk is set at create time only
  order        = 5
  validation {
    min = local.profile.disk
    max = 200
  }
}

# ------------------------------------------------------------------
# Presets — disabled for this template.
#
# Each preset would only set the `tools` multi-select, which the user can
# already tick directly. Presets earn their keep when they bundle MANY
# parameters at once (region + image + tool + env vars + sizing) so users
# pick one blessed configuration instead of filling many fields. With a
# single parameter to set, they are decorative — uncomment to re-enable.
# ------------------------------------------------------------------
# data "coder_workspace_preset" "minimal" {
#   name = "Minimal (no IDE)"
#   parameters = {
#     (data.coder_parameter.tools.name) = jsonencode([])
#   }
# }
#
# data "coder_workspace_preset" "intellij_only" {
#   name = "IntelliJ only"
#   parameters = {
#     (data.coder_parameter.tools.name) = jsonencode(["intellij"])
#   }
# }
#
# data "coder_workspace_preset" "vscode_only" {
#   name = "VS Code only"
#   parameters = {
#     (data.coder_parameter.tools.name) = jsonencode(["vscode"])
#   }
# }
#
# data "coder_workspace_preset" "fullstack" {
#   name = "Full-stack (IntelliJ + VS Code)"
#   parameters = {
#     (data.coder_parameter.tools.name) = jsonencode(["intellij", "vscode"])
#   }
# }
#
# data "coder_workspace_preset" "everything" {
#   name = "Everything (IntelliJ + VS Code + Cursor)"
#   parameters = {
#     (data.coder_parameter.tools.name) = jsonencode(["intellij", "vscode", "cursor"])
#   }
# }

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
    SELECTED="${join(",", local.selected)}"
    echo "🛠  Tools selected: $${SELECTED:-none}"
    echo "💻 CPU:    ${data.coder_parameter.cpu.value} cores"
    echo "🧠 Memory: ${data.coder_parameter.memory.value} GB"
    echo "💾 Disk:   ${data.coder_parameter.disk.value} GB (volume size hint)"

    for tool in $(echo "$SELECTED" | tr ',' ' '); do
      case "$tool" in
        intellij)
          echo "→ Installing IntelliJ Community (Projector / JetBrains Gateway-ready)…"
          ;;
        vscode)
          echo "→ VS Code will be available via the web IDE (code-server) display app."
          ;;
        cursor)
          echo "→ Installing Cursor…"
          ;;
      esac
    done
  EOT

  display_apps {
    vscode       = contains(local.selected, "vscode")
    web_terminal = true
    ssh_helper   = true
  }

  metadata {
    display_name = "Tools"
    key          = "tools"
    script       = "echo '${join(", ", local.selected)}'"
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

  cpu_shares = data.coder_parameter.cpu.value * 1024
  memory     = data.coder_parameter.memory.value * 1024 # MB
  # storage_opts.size only enforced on overlay2 + xfs (pquota) or btrfs.
  # On Docker Desktop (Win/Mac) it is accepted but advisory.
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
    label = "coder.tools"
    value = join(",", local.selected)
  }
}

output "selected_profile" {
  value = {
    tools  = local.selected
    cpu    = data.coder_parameter.cpu.value
    memory = data.coder_parameter.memory.value
    disk   = data.coder_parameter.disk.value
  }
}
