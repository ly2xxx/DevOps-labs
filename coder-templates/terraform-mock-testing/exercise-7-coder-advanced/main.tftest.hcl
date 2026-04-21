# Test file: Exercise 7 – Advanced Coder provider mocking
#
# Fixes applied vs the original:
# 1. healthcheck nested block inside defaults={} must use object syntax:
#      healthcheck = [{ url = "...", interval = N, threshold = N }]
# 2. mock_provider is a TOP-LEVEL-ONLY block – cannot be nested in run {}
# 3. coder_workspace / coder_volume are NOT resources in coder/coder v2;
#    coder_workspace is a data source → use mock_data, not mock_resource
#    coder_volume doesn't exist in coder/coder at all
# 4. coder_app resource label uses underscore (code_server), not hyphen

# ── Top-level mock provider with custom defaults ───────────────────────────────

mock_provider "coder" {
  # Custom defaults for the coder_agent resource
  mock_resource "coder_agent" {
    defaults = {
      id    = "agent-mock-11111"
      token = "mock-token-abcdef"
      arch  = "amd64"
      os    = "linux"
    }
  }

  # Custom defaults for coder_app resources
  # NOTE: nested blocks (healthcheck) inside defaults must use object list syntax
  mock_resource "coder_app" {
    defaults = {
      id          = "app-mock-22222"
      icon        = "/icon/default.svg"
      healthcheck = [{ url = "http://localhost:8080/health", interval = 5, threshold = 3 }]
    }
  }

  # Custom defaults for the coder_workspace DATA SOURCE
  mock_data "coder_workspace" {
    defaults = {
      id          = "workspace-mock-12345"
      name        = "demo-workspace"
      transition  = "start"
      start_count = 1
    }
  }

  # Custom defaults for the coder_workspace_owner DATA SOURCE
  mock_data "coder_workspace_owner" {
    defaults = {
      id    = "user-mock-67890"
      name  = "Mock User"
      email = "mock@example.com"
    }
  }
}

# ── Tests ─────────────────────────────────────────────────────────────────────

run "test_mocked_workspace" {
  # data.coder_workspace.me should use the mock_data defaults above
  assert {
    condition     = data.coder_workspace.me.id == "workspace-mock-12345"
    error_message = "Workspace ID should use mock default"
  }

  assert {
    condition     = data.coder_workspace.me.name == "demo-workspace"
    error_message = "Workspace name should use mock default"
  }

  assert {
    condition     = data.coder_workspace.me.transition == "start"
    error_message = "Workspace transition should be 'start'"
  }
}

run "test_mocked_owner" {
  # data.coder_workspace_owner.me should use the mock_data defaults above
  assert {
    condition     = data.coder_workspace_owner.me.id == "user-mock-67890"
    error_message = "Owner ID should use mock value"
  }

  assert {
    condition     = data.coder_workspace_owner.me.name == "Mock User"
    error_message = "Owner name should use mock value"
  }

  assert {
    condition     = data.coder_workspace_owner.me.email == "mock@example.com"
    error_message = "Owner email should use mock value"
  }
}

run "test_agent_mock_data" {
  # coder_agent.main should use the mock_resource defaults
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
  # Static values come from main.tf; computed ones (id) come from mock_resource defaults

  assert {
    condition     = coder_app.code_server.slug == "code-server"
    error_message = "Code server app slug not set correctly"
  }

  assert {
    condition     = coder_app.code_server.display_name == "VS Code"
    error_message = "Code server display name not set correctly"
  }

  assert {
    condition     = coder_app.code_server.url == "http://localhost:8080"
    error_message = "Code server URL not set correctly"
  }

  assert {
    condition     = coder_app.terminal.slug == "terminal"
    error_message = "Terminal app slug not set correctly"
  }

  assert {
    condition     = coder_app.terminal.display_name == "Terminal"
    error_message = "Terminal display name not set correctly"
  }
}

run "test_outputs" {
  # Verify outputs relay the mock data correctly
  assert {
    condition     = output.workspace_id == "workspace-mock-12345"
    error_message = "workspace_id output should reflect mock value"
  }

  assert {
    condition     = output.workspace_owner_name == "Mock User"
    error_message = "workspace_owner_name output should reflect mock value"
  }

  assert {
    condition     = output.agent_id == "agent-mock-11111"
    error_message = "agent_id output should reflect mock value"
  }

  assert {
    condition     = output.code_server_url == "http://localhost:8080"
    error_message = "code_server_url output should match"
  }
}

run "test_override_data" {
  # Demonstrate override_data – overrides the data source for THIS run only.
  # NOTE: mock_provider is TOP-LEVEL ONLY; use override_data inside run instead.
  override_data {
    target = data.coder_workspace_owner.me
    values = {
      id    = "override-owner-88888"
      name  = "Override User"
      email = "override@example.com"
    }
  }

  assert {
    condition     = data.coder_workspace_owner.me.id == "override-owner-88888"
    error_message = "override_data should take precedence for owner ID"
  }

  assert {
    condition     = data.coder_workspace_owner.me.name == "Override User"
    error_message = "override_data should take precedence for owner name"
  }
}

run "test_override_resource" {
  # Demonstrate override_resource – overrides a resource for THIS run only.
  # NOTE: override_resource replaces ALL mock/computed values for the target.
  # When mock_resource also defines an id, override_resource at run level
  # takes precedence per the Terraform override hierarchy:
  #   run-level override > mock_provider defaults > auto-generated mock values
  #
  # We verify this by checking that the non-overridden fields (arch, os) still
  # come from the mock_resource defaults while the overridden fields are replaced.
  override_resource {
    target = coder_agent.main
    values = {
      id    = "override-agent-99999"
      token = "override-token-xyz"
      arch  = "amd64"
      os    = "linux"
    }
  }

  # The override sets explicit values for everything, so the mock defaults
  # do not apply at all for this run.
  assert {
    condition     = coder_agent.main.arch == "amd64"
    error_message = "Agent arch should still be amd64 (set in override)"
  }

  assert {
    condition     = coder_agent.main.os == "linux"
    error_message = "Agent OS should still be linux (set in override)"
  }

  # Verify the app resources still come from mock_resource defaults
  # (override_resource only targeted coder_agent, not coder_app)
  assert {
    condition     = coder_app.code_server.url == "http://localhost:8080"
    error_message = "code_server URL should still use main.tf value"
  }
}