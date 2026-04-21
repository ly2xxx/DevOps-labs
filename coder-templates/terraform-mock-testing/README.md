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