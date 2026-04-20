# Exercise 1: Basic Provider Mocking
# This demonstrates how to mock AWS provider for S3 bucket testing

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the bucket"
  default     = {}
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket_id" {
  value = aws_s3_bucket.my_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.my_bucket.arn
}

output "bucket_domain_name" {
  value = aws_s3_bucket.my_bucket.bucket_domain_name
}