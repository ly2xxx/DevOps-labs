# Exercise 7: Coder Provider with Mock Namespace and user.me
# This demonstrates advanced mocking with custom mock data for Coder provider

terraform {
  required_providers {
    coder = {
      source = "hashicorp/coder"
    }
  }
}

# Simulate user data that would normally come from coder_provider
locals {
  # In real Coder, user.me provides current user information
  # We'll use a variable to simulate this
  current_user = var.user_email != "" ? {
    id        = "user-${var.user_email}"
    email     = var.user_email
    name      = var.user_name
    avatar_url = "https://avatars.example.com/${var.user_email}"
  } : null
}

variable "user_email" {
  type        = string
  default     = ""
  description = "Current user email (leave empty to use mock)"
}

variable "user_name" {
  type        = string
  default     = ""
  description = "Current user name"
}

variable "template_name" {
  type        = string
  default     = "demo-template"
}

# Coder workspace building block
resource "coder_workspace" "example" {
  name        = "demo-workspace"
  template_id = "template-id-placeholder"
  
  # Use owner reference
  owner_name = local.current_user != null ? local.current_user.name : "mocked-user"
  owner_id   = local.current_user != null ? local.current_user.id : "user-mocked"
}

# Coder agent - the connection to the development environment
resource "coder_agent" "main" {
  arch           = "amd64"
  os             = "linux"
  startup_script = <<-EOF
                  #!/bin/bash
                  echo "Starting development environment..."
                  EOF
}

# Coder app - a web application exposed in the workspace
resource "coder_app" "code-server" {
  name        = "code-server"
  display_name = "VS Code"
  icon        = "/icon/vscode.svg"
  url         = "http://localhost:8080"
  
  agent_id    = coder_agent.main.id
  
  # Healthcheck configuration
  healthcheck {
    url       = "http://localhost:8080/health"
    interval  = 5
    threshold = 3
  }
}

# Coder app - terminal
resource "coder_app" "terminal" {
  name        = "terminal"
  display_name = "Terminal"
  icon        = "/icon/terminal.svg"
  url         = "ws://localhost:8080/terminal"
  
  agent_id    = coder_agent.main.id
}

# Coder volume for persistent storage
resource "coder_volume" "home" {
  name        = "home"
  mount_path  = "/home/coder"
  size        = "10Gi"
}

output "workspace_id" {
  value = coder_workspace.example.id
}

output "workspace_name" {
  value = coder_workspace.example.name
}

output "workspace_owner" {
  value = coder_workspace.example.owner_name
}

output "agent_id" {
  value = coder_agent.main.id
}

output "code_server_url" {
  value = coder_app.code-server.url
}

output "volume_size" {
  value = coder_volume.home.size
}