# TFLint Configuration

# Enable AWS provider rules
plugin "aws" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Rule: Check for previous generation instance types
rule "aws_instance_previous_type" {
  enabled = true
}

# Rule: S3 bucket invalid ACL
rule "aws_s3_bucket_invalid_acl" {
  enabled = true
}
