# Config processor module
# This module reads a config file from S3 and processes it

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "config_key" {
  type        = string
  description = "Key of the config file in S3"
}

data "aws_s3_object" "config" {
  bucket = var.bucket_name
  key    = var.config_key
}

# Process the config (simplified for demo)
locals {
  config_data = jsondecode(data.aws_s3_object.config.body)
  
  processed_data = {
    environment = local.config_data.environment
    version     = local.config_data.version
    timestamp   = timestamp()
    processed   = true
  }
}

output "processed_data" {
  value = local.processed_data
}