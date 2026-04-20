# Mock data file with custom values for AWS resources
# This file provides specific values instead of random generated ones

# Define custom values for VPC resources
mock_resource "aws_vpc" {
  defaults = {
    arn = "arn:aws:ec2:us-east-1:123456789012:vpc/vpc-12345678"
    id  = "vpc-12345678"
  }
}

# Define custom values for subnet resources
mock_resource "aws_subnet" {
  defaults = {
    arn = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-12345678"
    id  = "subnet-12345678"
    # Availability zone will match the data source
    availability_zone = "us-east-1a"
  }
}

# Define custom values for security group resources
mock_resource "aws_security_group" {
  defaults = {
    arn       = "arn:aws:ec2:us-east-1:123456789012:security-group/sg-12345678"
    id        = "sg-12345678"
    owner_id  = "123456789012"
  }
}

# Define custom values for availability zones data source
mock_data "aws_availability_zones" {
  defaults = {
    id     = "custom-az-data"
    names  = ["us-east-1a", "us-east-1b", "us-east-1c"]
    zone_ids = ["use1-az1", "use1-az2", "use1-az3"]
  }
}