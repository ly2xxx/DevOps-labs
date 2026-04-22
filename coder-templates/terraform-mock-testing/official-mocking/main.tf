# main.tf

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

module "credentials" {
  source = "./modules/s3_data"

  data_bucket_name = "my_company_bucket_name"
}

resource "local_file" "credentials_json" {
  filename = "credentials.json"
  content  = jsonencode(module.credentials.data)
}
