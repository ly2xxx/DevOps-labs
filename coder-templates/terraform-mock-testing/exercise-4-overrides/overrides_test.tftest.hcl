# Test file demonstrating different types of overrides

mock_provider "aws" {}

# Override the S3 bucket resource at file level
override_resource {
  target = aws_s3_bucket.data_bucket
  values = {
    arn    = "arn:aws:s3:::my-data-bucket-override"
    bucket = "my-data-bucket-override"
  }
}

# Override the S3 object data source at file level
override_data {
  target = data.aws_s3_object.config_file
  values = {
    body = "{\"environment\":\"test\",\"version\":\"1.0.0\",\"database\":{\"host\":\"test-db.example.com\",\"port\":5432}}"
  }
}

run "test_resource_override" {
  # The bucket should use the overridden values
  assert {
    condition     = aws_s3_bucket.data_bucket.arn == "arn:aws:s3:::my-data-bucket-override"
    error_message = "Bucket ARN should use overridden value"
  }

  assert {
    condition     = aws_s3_bucket.data_bucket.bucket == "my-data-bucket-override"
    error_message = "Bucket name should use overridden value"
  }
}

run "test_data_source_override" {
  # The config file should use the overridden body
  assert {
    condition     = data.aws_s3_object.config_file.body != ""
    error_message = "Config file body should be overridden"
  }

  # Parse and validate the overridden config
  assert {
    condition     = can(jsondecode(data.aws_s3_object.config_file.body))
    error_message = "Overridden config should be valid JSON"
  }
}

run "test_module_override" {
  # Override the module output directly
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

  # Check that the module output uses overridden values
  assert {
    condition     = module.config_processor.processed_data.environment == "overridden"
    error_message = "Module environment should be overridden"
  }

  assert {
    condition     = module.config_processor.processed_data.version == "2.0.0"
    error_message = "Module version should be overridden"
  }
}

run "test_run_level_override_precedence" {
  # Run-level overrides take precedence over file-level overrides
  override_data {
    target = data.aws_s3_object.config_file
    values = {
      body = "{\"environment\":\"run-level\",\"version\":\"3.0.0\",\"database\":{\"host\":\"run-db.example.com\",\"port\":3306}}"
    }
  }

  # This should use the run-level override, not the file-level one
  assert {
    condition     = jsondecode(data.aws_s3_object.config_file.body).environment == "run-level"
    error_message = "Run-level override should take precedence"
  }

  assert {
    condition     = jsondecode(data.aws_s3_object.config_file.body).version == "3.0.0"
    error_message = "Run-level override should use different version"
  }
}

run "test_mock_provider_nested_override" {
  # Override within mock provider block (only applies when mock creates the resource)
  mock_provider "aws" {
    override_resource {
      target = aws_s3_bucket.data_bucket
      values = {
        arn    = "arn:aws:s3:::my-data-bucket-mock-override"
        bucket = "my-data-bucket-mock-override"
      }
    }
  }

  # In this run, the mock provider's nested override takes precedence
  assert {
    condition     = aws_s3_bucket.data_bucket.arn == "arn:aws:s3:::my-data-bucket-mock-override"
    error_message = "Mock provider nested override should take precedence"
  }

  assert {
    condition     = aws_s3_bucket.data_bucket.bucket == "my-data-bucket-mock-override"
    error_message = "Mock provider nested override should change bucket name"
  }
}