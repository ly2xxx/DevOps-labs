# Exercise 6: Mocking the coder/coder Provider
# This demonstrates mocking the Coder provider for template testing.
#
# Key schema facts for coder/coder v2:
#   DATA SOURCES:
#     data "coder_workspace"       – workspace metadata (name, id, transition, start_count)
#     data "coder_workspace_owner" – owner info (name, email, id) [split out in v2]
#     data "coder_parameter"       – user-configurable input shown in the Coder UI
#   RESOURCES:
#     coder_agent   – connects the workspace VM/container to Coder
#     coder_app     – exposes a web app inside the workspace

terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

variable "template_name" {
  type        = string
  description = "Name of the Coder template (used for labelling only)"
  default     = "dev-template"
}

# ── Data sources ──────────────────────────────────────────────────────────────

# Workspace metadata: name, id, transition, start_count
data "coder_workspace" "me" {}

# Owner information (split from coder_workspace in v2)
data "coder_workspace_owner" "me" {}

# CPU parameter – shown as a UI selector in the Coder dashboard
data "coder_parameter" "cpu" {
  name        = "CPU"
  type        = "number"
  default     = "2"
  description = "Number of CPU cores"
  mutable     = true

  option {
    name  = "2 cores"
    value = "2"
  }

  option {
    name  = "4 cores"
    value = "4"
  }

  option {
    name  = "8 cores"
    value = "8"
  }
}

# Memory parameter
data "coder_parameter" "memory" {
  name        = "Memory (GB)"
  type        = "number"
  default     = "4"
  description = "Amount of RAM in GB"
  mutable     = true

  option {
    name  = "4 GB"
    value = "4"
  }

  option {
    name  = "8 GB"
    value = "8"
  }

  option {
    name  = "16 GB"
    value = "16"
  }
}

# ── Resources ─────────────────────────────────────────────────────────────────

# The workspace agent – the real resource that the coder/coder provider manages
resource "coder_agent" "main" {
  arch           = "amd64"
  os             = "linux"
  startup_script = <<-EOF
    #!/bin/bash
    echo "Starting workspace '${data.coder_workspace.me.name}' for ${data.coder_workspace_owner.me.name}..."
    echo "CPU: ${data.coder_parameter.cpu.value} cores"
    echo "Memory: ${data.coder_parameter.memory.value} GB"
  EOF
}

# VS Code server app
resource "coder_app" "code_server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code"
  icon         = "/icon/vscode.svg"
  url          = "http://localhost:8080"

  healthcheck {
    url       = "http://localhost:8080/health"
    interval  = 5
    threshold = 3
  }
}

# Terminal app
resource "coder_app" "terminal" {
  agent_id     = coder_agent.main.id
  slug         = "terminal"
  display_name = "Terminal"
  icon         = "/icon/terminal.svg"
  url          = "ws://localhost:8080/terminal"
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "workspace_name" {
  value = data.coder_workspace.me.name
}

output "workspace_owner" {
  value = data.coder_workspace_owner.me.name
}

output "agent_id" {
  value = coder_agent.main.id
}

output "cpu_value" {
  value = data.coder_parameter.cpu.value
}

output "memory_value" {
  value = data.coder_parameter.memory.value
}

output "code_server_url" {
  value = coder_app.code_server.url
}