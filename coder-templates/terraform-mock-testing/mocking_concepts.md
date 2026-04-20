# Terraform Mock Testing: Core Concepts

This guide explains the behavior of mocks and overrides in Terraform's testing framework.

## 1. Scope and Precedence

The difference between where you place an override comes down to **Scope** (where it applies) and **Precedence** (which one wins).

### Global (Top-Level) Overrides
If you place an `override_resource` block at the top of your test file, it applies to **every** `run` block.
```hcl
# Global: Every bucket in every test will have this ARN by default
override_resource {
  target = aws_s3_bucket.main
  values = { arn = "arn:aws:s3:::global-default" }
}
```

### Provider-Level Overrides
Nesting inside a `mock_provider` limits the scope to resources managed by that specific provider alias.
```hcl
mock_provider "aws" {
  alias = "west"
  # Only resources using the 'west' alias will see this
  override_resource {
    target = aws_s3_bucket.main
    values = { arn = "arn:aws:s3:::west-coast-only" }
  }
}
```

### Run-Level Overrides (Inside `run`)
An `override_resource` block inside a `run` block **only** applies to that specific step and has the **highest precedence**.
```hcl
run "test_unique_scenario" {
  # This wins over Global and Provider overrides for this test only
  override_resource {
    target = aws_s3_bucket.main
    values = { arn = "arn:aws:s3:::special-test-case" }
  }
}
```

---

## 2. `mock_resource` vs `override_resource`

The difference between these two blocks is all about **Targeting** (General vs. Specific).

### `mock_resource` (Targets a Type)
Used to define behavior for **every resource of a certain type**.
*   **Example**: "Every S3 bucket I mock should have a consistent ARN format."
```hcl
mock_resource "aws_s3_bucket" {
  defaults = {
    arn = "arn:aws:s3:::mocked-bucket-id"
  }
}
# Result: aws_s3_bucket.primary AND aws_s3_bucket.secondary both get this ARN.
```

### `override_resource` (Targets an Address)
Used to define behavior for **one specific instance** by its unique path.
*   **Example**: "I need the primary bucket to have a very specific name for this one test."
```hcl
override_resource {
  target = aws_s3_bucket.primary
  values = {
    bucket = "strictly-validated-name"
  }
}
# Result: ONLY aws_s3_bucket.primary is affected. aws_s3_bucket.secondary is unchanged.
```

### Summary Table

| Feature | `mock_resource` | `override_resource` |
| :--- | :--- | :--- |
| **Target** | Resource **Type** (`"aws_instance"`) | Resource **Address** (`aws_instance.web`) |
| **Granularity** | Broad (General defaults) | Precise (Specific values) |
| **Common Location** | Mostly in `.tfmock.hcl` | Mostly in `.tftest.hcl` |
| **Use Case** | Setting up a realistic mock "world". | Overriding a specific value for a specific test. |
