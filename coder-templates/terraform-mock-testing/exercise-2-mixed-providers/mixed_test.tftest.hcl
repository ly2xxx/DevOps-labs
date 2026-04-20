# Test file demonstrating mixed real and mocked providers

# Define both real and mocked AWS providers
provider "aws" {
  region = "us-east-1"
}

mock_provider "aws" {
  alias = "mock"
}

run "test_with_mocked_provider" {
  # Use the mocked provider
  providers = {
    aws = aws.mock
  }

  variables {
    bucket_name      = "mocked-test-bucket"
    use_real_provider = false
  }

  assert {
    condition     = aws_s3_bucket.test_bucket.bucket == "mocked-test-bucket"
    error_message = "Bucket name was not set correctly with mocked provider"
  }

  assert {
    condition     = aws_s3_bucket.test_bucket.tags.Environment == "mocked"
    error_message = "Environment tag should indicate mocked provider"
  }

  # With mocked provider, caller identity will be generated (random string)
  assert {
    condition     = data.aws_caller_identity.current.arn != ""
    error_message = "Mocked caller identity should generate a value"
  }
}

run "test_with_real_provider" {
  # Use the real provider (requires AWS credentials)
  providers = {
    aws = aws
  }

  variables {
    bucket_name       = lower("real-test-bucket-${replace(timestamp(), ":", "-")}")
    use_real_provider = true
  }

  assert {
    condition     = aws_s3_bucket.test_bucket.bucket == var.bucket_name
    error_message = "Bucket name was not set correctly with real provider"
  }

  assert {
    condition     = aws_s3_bucket.test_bucket.tags.Environment == "real"
    error_message = "Environment tag should indicate real provider"
  }

  # With real provider, caller identity will be actual AWS account ARN
  assert {
    condition     = data.aws_caller_identity.current.arn != ""
    error_message = "Real caller identity should be available"
  }

  # Real provider should have a proper AWS ARN format
  assert {
    condition     = can(regex("^arn:aws:iam::", data.aws_caller_identity.current.arn))
    error_message = "Real caller identity should be a valid AWS ARN"
  }
}