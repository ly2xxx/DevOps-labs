"""
environment.py — Behave's lifecycle hooks file.

This file is automatically loaded by Behave before any tests run.
Use it for global setup/teardown (like configuring logging, verifying
prerequisites, or skipping all tests if the workspace is offline).

Hook execution order:
  before_all → before_feature → before_scenario → [test] → after_scenario → after_feature → after_all
"""

import os
import subprocess
import sys

SSH_TIMEOUT = 60  # seconds — used for both ping and per-command SSH calls


def before_all(context):
    """
    Runs once before the entire test suite.
    We verify the Coder CLI is available and the workspace is reachable.
    Fails fast with a clear message rather than hanging indefinitely.
    """
    context.workspace = os.environ.get("CODER_WORKSPACE", "my-claude-workspace")
    context.ssh_timeout = SSH_TIMEOUT

    # Check Coder CLI is installed
    try:
        result = subprocess.run(
            ["coder", "version"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode != 0:
            print("ERROR: 'coder' CLI not found. Install from https://coder.com/docs/cli")
            sys.exit(1)
    except subprocess.TimeoutExpired:
        print("ERROR: 'coder version' timed out — is the Coder CLI installed?")
        sys.exit(1)

    # Check the workspace is reachable within SSH_TIMEOUT seconds
    print(f"\n🔍 Pinging workspace '{context.workspace}' (timeout: {SSH_TIMEOUT}s)...")
    try:
        result = subprocess.run(
            ["coder", "ping", context.workspace, "--wait", f"{SSH_TIMEOUT}s"],
            capture_output=True,
            text=True,
            timeout=SSH_TIMEOUT + 5,  # +5s grace over the --wait value
        )
        if result.returncode != 0:
            print(f"\n❌ ERROR: Workspace '{context.workspace}' is not reachable.")
            print("   Make sure it is running: coder start my-claude-workspace")
            print(f"   Ping output: {result.stderr.strip()}")
            sys.exit(1)
    except subprocess.TimeoutExpired:
        print(
            f"\n❌ TIMEOUT ({SSH_TIMEOUT}s): Could not reach workspace '{context.workspace}'.\n"
            "   This is likely an SSH/agent connectivity issue, not a test failure.\n"
            "   Check: coder list   |   coder start my-claude-workspace"
        )
        sys.exit(1)

    print(f"✅ Workspace '{context.workspace}' is reachable. Running tests...\n")


def before_scenario(context, scenario):
    """Runs before each individual scenario."""
    print(f"\n--- Scenario: {scenario.name} ---")
    context.last_output = None
    context.last_exit_code = None


def after_scenario(context, scenario):
    """Runs after each individual scenario."""
    status = "✅ PASSED" if scenario.status == "passed" else "❌ FAILED"
    print(f"{status}: {scenario.name}")
