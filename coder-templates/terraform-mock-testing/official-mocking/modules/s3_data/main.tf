# ./modules/s3_data/main.tf

variable "data_bucket_name" {
  type = string
}

data "aws_s3_object" "data_bucket" {
  bucket = var.data_bucket_name
  key    = "credentials.json"
}

output "data" {
  value = jsondecode(data.aws_s3_object.data_bucket.body)
}
