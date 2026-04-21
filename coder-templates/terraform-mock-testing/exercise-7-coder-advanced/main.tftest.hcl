# Test file demonstrating advanced Coder provider mocking
# with mock namespace and custom user data

# Mock data file with custom values for Coder resources
mock_provider "coder" {
  # Load additional mock data from embedded blocks
  mock_resource "coder_workspace" {
    defaults = {
      id         = "workspace-mock-12345"
      owner_id   = "user-mock-67890"
      owner_name = "Mock User"
    }
  }

  mock_resource "coder_agent" {
    defaults = {
      id     = "agent-mock-11111"
      token  = "mock-token-abcdef"
      arch   = "amd64"
      os     = "linux"
    }
  }

  mock_resource "coder_app" {
    defaults = {
      id      = "app-mock-22222"
      icon    = "/icon/default.svg"
      healthcheck {
        url        = "http://localhost:8080/health"
        interval   = 5
        threshold  = 3
      }
    }
  }

  mock_resource "coder_volume" {
    defaults = {
      id         = "volume-mock-33333"
      mount_path = "/home/coder"
      size       = "10Gi"
    }
  }
}

run "test_mocked_workspace" {
  variables {
    user_email = ""
    user_name  = ""
  }

  # The workspace should use mocked values since no user provided
  assert {
    condition     = coder_workspace.example.owner_name == "mocked-user"
    error_message = "Should use mocked user name when no user provided"
  }

  # Workspace ID should be from mock data
  assert {
    condition     = coder_workspace.example.id == "workspace-mock-12345"
    error_message = "Workspace ID should use mock value"
  }

  assert {
    condition     = coder_workspace.example.owner_id == "user-mock-67890"
    error_message = "Owner ID should use mock value"
  }
}

run "test_with_custom_user" {
  variables {
    user_email = "developer@example.com"
    user_name  = "John Developer"
  }

  # When user data is provided, it should override the mock
  assert {
    condition     = coder_workspace.example.owner_name == "John Developer"
    error_message = "Should use provided user name"
  }

  assert {
    condition     = coder_workspace.example.owner_id == "user-developer@example.com"
    error_message = "Should use derived user ID from email"
  }
}

run "test_agent_mock_data" {
  variables {
    user_email = "test@example.com"
    user_name  = "Test User"
  }

  # Agent should use mocked values
  assert {
    condition     = coder_agent.main.id == "agent-mock-11111"
    error_message = "Agent ID should use mock value"
  }

  assert {
    condition     = coder_agent.main.arch == "amd64"
    error_message = "Agent arch should be amd64"
  }

  assert {
    condition     = coder_agent.main.os == "linux"
    error_message = "Agent OS should be linux"
  }
}

run "test_apps_mock_data" {
  variables {
    user_email = "app@example.com"
    user_name  = "App User"
  }

  # Check code-server app
  assert {
    condition     = coder_app.code-server.name == "code-server"
    error_message = "Code server app name not set correctly"
  }

  assert {
    condition     = coder_app.code-server.display_name == "VS Code"
    error_message = "Code server display name not set correctly"
  }

  assert {
    condition     = coder_app.code-server.url == "http://localhost:8080"
    error_message = "Code server URL not set correctly"
  }

  # Check terminal app
  assert {
    condition     = coder_app.terminal.name == "terminal"
    error_message = "Terminal app name not set correctly"
  }

  assert {
    condition     = coder_app.terminal.display_name == "Terminal"
    error_message = "Terminal display name not set correctly"
  }
}

run "test_volume_mock_data" {
  variables {
    user_email = "volume@example.com"
    user_name  = "Volume User"
  }

  assert {
    condition     = coder_volume.home.name == "home"
    error_message = "Volume name not set correctly"
  }

  assert {
    condition     = coder_volume.home.mount_path == "/home/coder"
    error_message = "Volume mount path not set correctly"
  }

  assert {
    condition     = coder_volume.home.size == "10Gi"
    error_message = "Volume size not set correctly"
  }
}

run "test_override_resource" {
  # Demonstrate resource override
  mock_provider "coder" {}

  override_resource {
    target = coder_workspace.example
    values = {
      id         = "override-workspace-99999"
      owner_id   = "override-owner-88888"
      owner_name = "Override User"
    }
  }

  variables {
    user_email = ""
    user_name  = ""
  }

  # The override should take precedence
  assert {
    condition     = coder_workspace.example.id == "override-workspace-99999"
    error_message = "Override should take precedence for workspace ID"
  }

  assert {
    condition     = coder_workspace.example.owner_id == "override-owner-88888"
    error_message = "Override should take precedence for owner ID"
  }

  assert {
    condition     = coder_workspace.example.owner_name == "Override User"
    error_message = "Override should take precedence for owner name"
  }
}