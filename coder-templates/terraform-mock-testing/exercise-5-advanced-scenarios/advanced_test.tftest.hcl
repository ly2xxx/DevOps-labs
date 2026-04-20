# Test file demonstrating advanced scenarios with repeated blocks

mock_provider "aws" {
  # Custom mock data for DynamoDB table
  # Note: Repeated blocks with computed attributes share the same mock values
  mock_resource "aws_dynamodb_table" {
    defaults = {
      arn = "arn:aws:dynamodb:us-east-1:123456789012:table/test-table"
      id  = "test-table"
      # The replica block has computed arn attribute
      # For repeated blocks, provide a single object of defaults
      replica = {
        arn = "arn:aws:dynamodb:eu-west-2:123456789012:table/test-table"
      }
    }
  }
}

# Specialized mock provider for plan-phase testing
mock_provider "aws" {
  alias           = "plan_testing"
  override_during = plan

  mock_resource "aws_dynamodb_table" {
    defaults = {
      arn = "arn:aws:dynamodb:us-east-1:123456789012:table/plan-override-table"
      id  = "plan-override-table"
    }
  }
}

run "test_basic_table_creation" {
  variables {
    table_name      = "my-dynamodb-table"
    read_capacity   = 10
    write_capacity  = 10
    replica_regions = ["eu-west-2", "us-east-1"]
  }

  assert {
    condition     = aws_dynamodb_table.main.name == "my-dynamodb-table"
    error_message = "Table name not set correctly"
  }

  assert {
    condition     = aws_dynamodb_table.main.billing_mode == "PROVISIONED"
    error_message = "Billing mode should be PROVISIONED"
  }
}

run "test_replica_blocks" {
  variables {
    table_name      = "replica-table"
    read_capacity   = 5
    write_capacity  = 5
    replica_regions = ["eu-west-2", "us-east-1", "us-west-2"]
  }

  # Check that we have 3 replicas
  assert {
    condition     = length(aws_dynamodb_table.main.replica) == 3
    error_message = "Should have 3 replica blocks"
  }

  # All replicas share the same ARN from the mock
  assert {
    condition     = length(aws_dynamodb_table.main.replica[*].arn) == 3
    error_message = "Should have 3 replica ARNs"
  }

  assert {
    condition     = tolist(aws_dynamodb_table.main.replica)[0].arn == "arn:aws:dynamodb:eu-west-2:123456789012:table/test-table"
    error_message = "First replica ARN should match mock"
  }
}

run "test_gsi_configuration" {
  variables {
    table_name      = "gsi-table"
    read_capacity   = 20
    write_capacity  = 20
    replica_regions = ["eu-west-2"]
  }

  assert {
    condition     = length(aws_dynamodb_table.main.global_secondary_index) == 1
    error_message = "Should have 1 GSI"
  }

  assert {
    condition     = tolist(aws_dynamodb_table.main.global_secondary_index)[0].name == "email-index"
    error_message = "GSI name should be email-index"
  }

  assert {
    condition     = tolist(aws_dynamodb_table.main.global_secondary_index)[0].read_capacity == 20
    error_message = "GSI read capacity should match"
  }
}

run "test_override_during_plan" {
  # Use the specialized provider for plan-phase testing
  providers = {
    aws = aws.plan_testing
  }

  command = plan

  variables {
    table_name      = "plan-override-test"
    read_capacity   = 5
    write_capacity  = 5
    replica_regions = ["eu-west-2"]
  }

  # Values should be generated during plan thanks to override_during = plan
  assert {
    condition     = aws_dynamodb_table.main.arn != ""
    error_message = "ARN should be generated during plan"
  }

  assert {
    condition     = aws_dynamodb_table.main.id != ""
    error_message = "ID should be generated during plan"
  }
}