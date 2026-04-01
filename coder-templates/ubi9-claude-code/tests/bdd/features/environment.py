"""
environment.py — Behave's lifecycle hooks file.

This file is automatically loaded by Behave before any tests run.
Use it for global setup/teardown (like configuring logging, verifying
prerequisites, or skipping all tests if the workspace is offline).

Hook execution order:
  before_all → before_feature → before_scenario → [test] → after_scenario → after_feature → after_all
"""

import subprocess
import sys


def before_all(context):
    """
    Runs once before the entire test suite.
    We verify the Coder CLI is available and the workspace exists.
    """
    workspace = "my-claude-workspace"

    # Check Coder CLI is installed
    result = subprocess.run(
        ["coder", "version"], capture_output=True, text=True
    )
    if result.returncode != 0:
        print("ERROR: 'coder' CLI not found. Install from https://coder.com/docs/cli")
        sys.exit(1)

    # Check the workspace is reachable
    result = subprocess.run(
        ["coder", "ping", workspace, "--wait", "10s"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: Workspace '{workspace}' is not reachable.")
        print("Make sure your workspace is running: coder start my-claude-workspace")
        sys.exit(1)

    print(f"\n✅ Workspace '{workspace}' is reachable. Running tests...\n")


def before_scenario(context, scenario):
    """Runs before each individual scenario."""
    print(f"\n--- Scenario: {scenario.name} ---")


def after_scenario(context, scenario):
    """Runs after each individual scenario."""
    status = "✅ PASSED" if scenario.status == "passed" else "❌ FAILED"
    print(f"{status}: {scenario.name}")
