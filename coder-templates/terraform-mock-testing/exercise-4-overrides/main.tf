# Exercise 4: Overrides
# This demonstrates resource, data source, and module overrides

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-data-bucket"
}

data "aws_s3_object" "config_file" {
  bucket = aws_s3_bucket.data_bucket.bucket
  key    = "config.json"
}

# Module that processes the config file
module "config_processor" {
  source = "./modules/config-processor"

  bucket_name = aws_s3_bucket.data_bucket.bucket
  config_key  = "config.json"
}

# Resource that depends on module output
resource "local_file" "processed_config" {
  filename = "processed-config.json"
  content  = jsonencode(module.config_processor.processed_data)
}

output "bucket_arn" {
  value = aws_s3_bucket.data_bucket.arn
}

output "config_content" {
  value = data.aws_s3_object.config_file.body
}

output "module_output" {
  value = module.config_processor.processed_data
}