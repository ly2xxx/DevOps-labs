# Test file demonstrating different types of overrides

mock_provider "aws" {}

# Specialized mock provider with an alias (must be at top level)
mock_provider "aws" {
  alias = "special"
}

# Standard data overrides at top level
override_data {
  target = data.aws_s3_object.config_file
  values = {
    body = "{\"environment\":\"test\",\"version\":\"1.0.0\"}"
  }
}

override_data {
  target = module.config_processor.data.aws_s3_object.config
  values = {
    body = "{\"environment\":\"test\",\"version\":\"1.0.0\"}"
  }
}

run "test_resource_override" {
  command = plan

  override_resource {
    target          = aws_s3_bucket.data_bucket
    override_during = plan
    values = {
      arn    = "arn:aws:s3:::my-test-override"
      bucket = "my-test-override"
    }
  }

  assert {
    condition     = aws_s3_bucket.data_bucket.arn == "arn:aws:s3:::my-test-override"
    error_message = "Resource override failed"
  }
}

run "test_module_override" {
  override_module {
    target = module.config_processor
    outputs = {
      processed_data = {
        environment = "overridden"
        version     = "2.0.0"
        timestamp   = "2026-04-20T20:00:00Z"
        processed   = true
      }
    }
  }

  assert {
    condition     = module.config_processor.processed_data.environment == "overridden"
    error_message = "Module override failed"
  }
}

run "test_nested_provider_override" {
  # Use the aliased mock provider to demonstrate provider switching.
  # With a mock provider, all computed attributes (like arn) are generated
  # as random strings. We verify the mock provider is active by confirming
  # the arn is non-empty and that our static attribute (bucket name from
  # main.tf) is set correctly.
  providers = {
    aws = aws.special
  }

  assert {
    condition     = aws_s3_bucket.data_bucket.arn != ""
    error_message = "Aliased mock provider should generate a non-empty ARN"
  }

  assert {
    condition     = aws_s3_bucket.data_bucket.bucket == "my-data-bucket"
    error_message = "Bucket name should match the value set in main.tf"
  }
}