# Terraform Mock Testing: Core Concepts

This guide explains the behavior of mocks and overrides in Terraform's testing framework.

## 1. Scope and Precedence

The difference between where you place an override comes down to **Scope** (where it applies) and **Precedence** (which one wins).

### Global (Top-Level) Overrides
If you place an `override_resource` block at the top of your test file (not inside any other block), it is **Global**.
*   **Scope**: It applies to **every** `run` block in that file.
*   **Use Case**: Use this for shared infrastructure (like a base VPC) that all your tests should see by default.

### Provider-Level Overrides
You can nest `override_resource` inside a `mock_provider` block.
*   **Scope**: It only applies to resources managed by that specific provider (or alias).
*   **Use Case**: Useful when mocking multiple providers (e.g., different AWS regions) with unique values for each.

### Run-Level Overrides (Inside `run`)
An `override_resource` block placed inside a `run` block is **Local**.
*   **Scope**: It **only** applies to that specific `run` step.
*   **Use Case**: Testing specific failure conditions or unique values needed for one particular test case.

### Precedence Hierarchy (Highest to Lowest)

| Order | Location | Description |
| :--- | :--- | :--- |
| **1 (Highest)** | **Inside a `run` block** | Best for specific edge cases; overrides everything else. |
| **2** | **Inside a `mock_provider`** | Provider-specific logic. |
| **3 (Lowest)** | **Top-Level (Global)** | Sets the "Standard" mock baseline for the whole file. |

---

## 2. `mock_resource` vs `override_resource`

The difference between these two blocks is all about **Targeting** (General vs. Specific).

### `mock_resource` (Targets a Type)
Used to define behavior for **every resource of a certain type**.
*   **Target**: A resource type string (e.g., `"aws_s3_bucket"`).
*   **Logic**: "If any bucket is created by this provider, give it these default attributes."
*   **Best For**: Creating a realistic baseline for a provider (e.g., ensuring all DynamoDB tables have a mocked ARN format).

### `override_resource` (Targets an Address)
Used to define behavior for **one specific instance**.
*   **Target**: A resource address (e.g., `aws_s3_bucket.main`).
*   **Logic**: "Specifically for the resource named 'main', hijack it and force these exact values."
*   **Best For**: Fine-grained assertions where you need to know the exact ID or ARN of a specific resource to test downstream dependencies.

### Summary Table

| Feature | `mock_resource` | `override_resource` |
| :--- | :--- | :--- |
| **Target** | Resource **Type** (`"aws_instance"`) | Resource **Address** (`aws_instance.web`) |
| **Granularity** | Broad (General defaults) | Precise (Specific values) |
| **Common Location** | Mostly in `.tfmock.hcl` | Mostly in `.tftest.hcl` |
