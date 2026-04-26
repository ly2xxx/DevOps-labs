# Terraform Mock Testing Lab

## Overview
This lab explores Terraform's provider mocking functionality (available in Terraform v1.7.0+). You'll learn how to mock providers, resources, and data sources to test your modules without creating real infrastructure or requiring credentials.

## Prerequisites
- Terraform v1.7.0 or later
- Understanding of Terraform basics
- Familiarity with Terraform test language

## Lab Structure

### Exercise 1: Basic Provider Mocking
- Mock AWS provider for S3 bucket testing
- Understanding generated data patterns

### Exercise 2: Mixed Real and Mocked Providers
- Using both real and mocked providers in tests
- Provider aliasing for different scenarios

### Exercise 3: Custom Mock Data
- Providing specific values with mock_resource blocks
- Mock data files and sharing between tests

### Exercise 4: Overrides
- override_resource for resource value overrides
- override_data for data source overrides
- override_module for entire module overrides

### Exercise 5: Advanced Scenarios
- Handling repeated blocks and nested attributes
- Testing complex multi-provider modules

### Exercise 6: Coder Provider Mocking
- Mocking hashicorp/coder provider
- Testing templates, workspaces, and parameters
- Understanding generated IDs and attributes

### Exercise 7: Coder Provider Advanced
- Mock namespace with custom mock data
- Simulating user.me data
- Testing workspace agents, apps, and volumes
- Override resource blocks

## Getting Started
Each exercise is in its own subdirectory. Navigate to any exercise directory and run:
```bash
terraform test
```

## Key Concepts Covered

1. **mock_provider**: Creates fake provider instances
2. **Generated Data**: How Terraform generates values for computed attributes
3. **Mock Data**: Providing specific values for resources and data sources
4. **Overrides**: Overriding values at resource, data source, or module level
5. **Scope and Precedence**: Understanding override hierarchy

## Documentation
Reference: [Terraform Provider Mocking](https://developer.hashicorp.com/terraform/language/tests/mocking)

Here are the best Terraform testing tutorials I found:

## 📚 Top Picks

### 1. **Official HashiCorp Tutorial** (Best for built-in testing)
**Write Terraform Tests**
🔗 https://developer.hashicorp.com/terraform/tutorials/configuration-language/test
- Covers Terraform's built-in `terraform test` command
- Shows run blocks, plan/apply validation
- Direct from HashiCorp - authoritative

### 2. **Terratest by Gruntwork** (Industry standard for advanced testing)
**Quick Start**
🔗 https://terratest.gruntwork.io/docs/getting-started/quick-start/
- Go-based infrastructure testing
- Examples for AWS, GCP, Azure
- More powerful than built-in tests

### 3. **Comprehensive Comparison**
**Terratest vs Terraform/OpenTofu Test**
🔗 https://www.env0.com/blog/terratest-vs-terraform-opentofu-test-in-depth-comparison
- Side-by-side comparison
- When to use each approach

### 4. **Spacelift Guide** (Strategy overview)
**How to Test Terraform Code**
🔗 https://spacelift.io/blog/terraform-test
- Covers: terraform test, Terratest, TFLint, Checkov
- Unit, integration, compliance, drift testing

### 5. **Microsoft Learn** (Azure-focused practical guide)
**End-to-end Terratest testing**
🔗 https://learn.microsoft.com/en-us/azure/developer/terraform/best-practices-end-to-end-testing

---

## 🎯 Recommendation

- **Start with:** HashiCorp's official tutorial (#1) - uses native `terraform test`
- **For CI/CD & production:** Terratest (#2) - more powerful but requires Go

Which approach are you looking for?