# Exercise 7: Advanced Coder Provider Mocking
# Demonstrates: custom mock data, coder_workspace_owner data source,
# coder_agent, coder_app, override_resource inside run blocks.
#
# coder/coder v2 schema recap:
#   DATA SOURCES: coder_workspace, coder_workspace_owner, coder_parameter
#   RESOURCES:    coder_agent, coder_app
#   NOTE: coder_workspace and coder_volume are NOT resources in coder/coder.
#         Persistent storage is managed by the underlying infrastructure
#         provider (docker_volume, kubernetes_persistent_volume_claim, etc.)

terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

variable "user_email" {
  type        = string
  default     = ""
  description = "Override user email displayed in startup script (leave empty for mock)"
}

variable "user_name" {
  type        = string
  default     = ""
  description = "Override user name displayed in startup script (leave empty for mock)"
}

variable "template_name" {
  type        = string
  default     = "demo-template"
}

# ── Data sources ──────────────────────────────────────────────────────────────

# Workspace metadata
data "coder_workspace" "me" {}

# Owner information (split from coder_workspace in v2)
data "coder_workspace_owner" "me" {}

# ── Resources ─────────────────────────────────────────────────────────────────

# Workspace agent – the real managed resource
resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"

  startup_script = <<-EOF
    #!/bin/bash
    echo "Starting workspace '${data.coder_workspace.me.name}'..."
    echo "Owner: ${data.coder_workspace_owner.me.name} (${data.coder_workspace_owner.me.email})"
    echo "Template: ${var.template_name}"
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

output "workspace_id" {
  value = data.coder_workspace.me.id
}

output "workspace_name" {
  value = data.coder_workspace.me.name
}

output "workspace_owner_name" {
  value = data.coder_workspace_owner.me.name
}

output "workspace_owner_email" {
  value = data.coder_workspace_owner.me.email
}

output "agent_id" {
  value = coder_agent.main.id
}

output "code_server_url" {
  value = coder_app.code_server.url
}

output "terminal_slug" {
  value = coder_app.terminal.slug
}