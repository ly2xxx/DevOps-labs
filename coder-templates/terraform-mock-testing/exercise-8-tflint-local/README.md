# Exercise 8: Running TFLint Locally

## Objective
Learn to run TFLint locally in your IDE to catch Terraform issues early.

## What is TFLint?
TFLint is a **linter** for Terraform that finds:
- Syntax errors
- Best practice violations
- Deprecated attributes
- Naming convention issues
- Security problems

## Pre-requisites
Install TFLint:
```bash
# macOS
brew install tflint

# Windows (winget)
winget search tflint
winget install TerraformLinters.tflint
or
Invoke-WebRequest -Uri https://raw.githubusercontent.com/terraform-linters/tflint/master/install_windows.ps1 -OutFile install_tflint.ps1
.\install_tflint.ps1

# Linux
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install/install.sh | bash
```

Or download from: https://github.com/terraform-linters/tflint/releases

## The Exercise

This directory contains a Terraform configuration with **intentional issues**. Your task:

### Step 1: Run TFLint
```bash
tflint --init
tflint
```

### Step 2: Review the Issues
TFLint should report several issues. Can you fix them?

### Step 3: Fix and Re-run
Fix the issues and run TFLint again to verify.

## Issues to Find

Can you identify what's wrong in `main.tf`? Hint:
- Naming convention violation
- Deprecated attribute usage
- Missing required attribute
- Best practice violation

## Solution
See `solution.md` for the answers after you've tried!
