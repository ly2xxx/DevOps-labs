Feature: SSH Echo Test
  As a developer
  I want to verify SSH connectivity to my Coder workspace
  So that I can confirm the workspace agent is alive and responding

  Background:
    Given I have SSH access to the Coder workspace

  Scenario: Basic echo command returns expected output
    When I run the command "echo hello"
    Then the output should be "hello"

  Scenario: Echo a multi-word string
    When I run the command "echo hello from coder"
    Then the output should be "hello from coder"

  Scenario: Echo environment variable
    When I run the command "echo $HOME"
    Then the output should contain "/home/coder"

  Scenario: Verify current user is coder
    When I run the command "whoami"
    Then the output should be "coder"

  Scenario: Verify Node.js is available
    When I run the command "node --version"
    Then the output should start with "v"
