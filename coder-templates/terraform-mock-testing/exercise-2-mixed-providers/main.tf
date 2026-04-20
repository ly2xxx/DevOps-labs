# Exercise 2: Mixed Real and Mocked Providers
# This demonstrates using both real and mocked providers in tests

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration (will be used with real credentials)
provider "aws" {
  region = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "use_real_provider" {
  type        = bool
  description = "Whether to use real AWS provider (requires credentials)"
  default     = false
}

# This resource will be created differently based on provider choice
resource "aws_s3_bucket" "test_bucket" {
  bucket = var.bucket_name
  
  tags = {
    Name        = var.bucket_name
    Environment = var.use_real_provider ? "real" : "mocked"
    TestType    = "mixed-provider-test"
  }
}

# Data source to get caller identity (works differently with real vs mocked)
data "aws_caller_identity" "current" {}

output "bucket_id" {
  value = aws_s3_bucket.test_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.test_bucket.arn
}

output "caller_identity" {
  value = data.aws_caller_identity.current.arn
}

output "is_real_provider" {
  value = var.use_real_provider
}