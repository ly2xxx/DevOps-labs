"""
Step definitions for SSH echo tests.

Behave links the Gherkin steps in the .feature file to these Python functions.
Each decorator (@given, @when, @then) matches a line from the feature file.

Requirements:
    pip install behave paramiko
"""

import subprocess
from behave import given, when, then

SSH_TIMEOUT = 60  # seconds — all coder ssh calls will fail after this


# ---------------------------------------------------------------------------
# Context setup
# ---------------------------------------------------------------------------

@given("I have SSH access to the Coder workspace")
def step_have_ssh_access(context):
    """
    'context' is Behave's shared state object — like a test fixture.
    We store the workspace name here so all steps in this scenario can use it.
    You can override CODER_WORKSPACE via environment variable before running.
    """
    import os
    context.workspace = os.environ.get("CODER_WORKSPACE", "my-claude-workspace")
    context.last_output = None
    context.last_exit_code = None


# ---------------------------------------------------------------------------
# When steps — actions
# ---------------------------------------------------------------------------

@when('I run the command "{command}"')
def step_run_command(context, command):
    """
    Runs a shell command inside the Coder workspace over SSH using
    the `coder ssh` CLI tool.

    `coder ssh <workspace> -- <command>` executes a single command and exits.
    The output is captured and stored on context for the Then steps to assert.
    Times out after SSH_TIMEOUT seconds — a clear signal of an agent/SSH issue.
    """
    try:
        result = subprocess.run(
            ["coder", "ssh", context.workspace, "--", command],
            capture_output=True,
            text=True,
            timeout=SSH_TIMEOUT,
        )
        context.last_output = result.stdout.strip()
        context.last_exit_code = result.returncode
    except subprocess.TimeoutExpired:
        raise AssertionError(
            f"SSH command timed out after {SSH_TIMEOUT}s: '{command}'\n"
            f"Workspace: {context.workspace}\n"
            "This is likely an SSH/agent connectivity issue."
        )


# ---------------------------------------------------------------------------
# Then steps — assertions
# ---------------------------------------------------------------------------

@then('the output should be "{expected}"')
def step_output_equals(context, expected):
    """Exact match assertion."""
    assert context.last_exit_code == 0, (
        f"Command failed with exit code {context.last_exit_code}"
    )
    assert context.last_output == expected, (
        f"Expected: '{expected}'\n"
        f"Got:      '{context.last_output}'"
    )


@then('the output should contain "{expected}"')
def step_output_contains(context, expected):
    """Substring match assertion."""
    assert context.last_exit_code == 0, (
        f"Command failed with exit code {context.last_exit_code}"
    )
    assert expected in context.last_output, (
        f"Expected output to contain: '{expected}'\n"
        f"Got: '{context.last_output}'"
    )


@then('the output should start with "{prefix}"')
def step_output_starts_with(context, prefix):
    """Prefix match assertion."""
    assert context.last_exit_code == 0, (
        f"Command failed with exit code {context.last_exit_code}"
    )
    assert context.last_output.startswith(prefix), (
        f"Expected output to start with: '{prefix}'\n"
        f"Got: '{context.last_output}'"
    )
