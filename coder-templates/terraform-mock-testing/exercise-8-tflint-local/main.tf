# This Terraform configuration has intentional issues for TFLint exercise

provider "aws" {
  region = "eu-west-1"
}

# Issue 1: Resource name uses camelCase instead of snake_case
resource "aws_s3_bucket" "MyBucket" {
  # Issue 2: Using deprecated attribute
  bucket = "my-intentional-bucket-name"

  # Issue 3: Missing tags (best practice violation)
  # Issue 4: acl is deprecated, use versioning or other settings instead
  acl = "private"
}

# Issue 5: Missing required tag
resource "aws_instance" "webServer" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # Missing tags
}
