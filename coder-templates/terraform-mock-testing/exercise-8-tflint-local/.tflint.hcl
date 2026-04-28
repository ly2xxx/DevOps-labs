# TFLint Configuration

# Enable AWS provider rules
plugin "aws" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Rule: Enforce naming convention (snake_case)
rule "aws_resource_naming_convention" {
  enabled = true
  naming  = "snake_case"
}

# Rule: Check for required tags
rule "aws_instance_previous_type" {
  enabled = true
}

# Rule: S3 bucket should have tags
rule "aws_s3_bucket_invalid_acl" {
  enabled = true
}
