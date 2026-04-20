# Exercise 5: Advanced Mocking Scenarios
# This demonstrates complex scenarios with repeated blocks and nested attributes

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table"
}

variable "read_capacity" {
  type        = number
  default     = 5
}

variable "write_capacity" {
  type        = number
  default     = 5
}

variable "replica_regions" {
  type        = list(string)
  default     = ["eu-west-2", "us-east-1"]
}

# DynamoDB table with replica blocks (complex nested attributes)
resource "aws_dynamodb_table" "main" {
  name           = var.table_name
  billing_mode   = "PROVISIONED"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    projection_type = "ALL"
    read_capacity  = var.read_capacity
    write_capacity = var.write_capacity
  }

  # Replica blocks - each has computed ARN attributes
  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
    }
  }

  tags = {
    Name        = var.table_name
    Environment = "test"
  }
}

output "table_id" {
  value = aws_dynamodb_table.main.id
}

output "table_arn" {
  value = aws_dynamodb_table.main.arn
}

output "replica_count" {
  value = length(aws_dynamodb_table.main.replica)
}

output "replica_arns" {
  value = aws_dynamodb_table.main.replica[*].arn
}