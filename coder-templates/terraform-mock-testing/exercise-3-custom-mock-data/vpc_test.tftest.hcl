# Test file demonstrating custom mock data usage

# Mock provider that loads custom data from file
mock_provider "aws" {
  source = "./"  # Load from current directory
}

run "test_vpc_with_custom_values" {
  variables {
    vpc_cidr    = "10.1.0.0/16"
    subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "10.1.0.0/16"
    error_message = "VPC CIDR block not set correctly"
  }

  # These should use our custom mock values, not random strings
  assert {
    condition     = aws_vpc.main.arn == "arn:aws:ec2:us-east-1:123456789012:vpc/vpc-12345678"
    error_message = "VPC ARN should use custom mock value"
  }

  assert {
    condition     = aws_vpc.main.id == "vpc-12345678"
    error_message = "VPC ID should use custom mock value"
  }
}

run "test_subnets_with_custom_values" {
  variables {
    vpc_cidr     = "10.2.0.0/16"
    subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24"]
  }

  # Check that we have 2 subnets
  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should have created 2 subnets"
  }

  # All subnets should use the same custom ARN (limitation of mocking)
  assert {
    condition     = alltrue([
      for arn in aws_subnet.public[*].arn :
      arn == "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-12345678"
    ])
    error_message = "All subnet ARNs should use custom mock value"
  }

  # Check CIDR blocks are set correctly from configuration
  assert {
    condition     = aws_subnet.public[0].cidr_block == "10.2.1.0/24"
    error_message = "First subnet CIDR not set correctly"
  }

  assert {
    condition     = aws_subnet.public[1].cidr_block == "10.2.2.0/24"
    error_message = "Second subnet CIDR not set correctly"
  }
}

run "test_security_group_with_custom_values" {
  variables {
    vpc_cidr     = "10.3.0.0/16"
    subnet_cidrs = ["10.3.1.0/24"]
  }

  assert {
    condition     = aws_security_group.web.name == "web-sg"
    error_message = "Security group name not set correctly"
  }

  # Check custom mock values
  assert {
    condition     = aws_security_group.web.arn == "arn:aws:ec2:us-east-1:123456789012:security-group/sg-12345678"
    error_message = "Security group ARN should use custom mock value"
  }

  assert {
    condition     = aws_security_group.web.id == "sg-12345678"
    error_message = "Security group ID should use custom mock value"
  }

  assert {
    condition     = aws_security_group.web.owner_id == "123456789012"
    error_message = "Security group owner ID should use custom mock value"
  }
}

run "test_data_source_custom_values" {
  variables {
    vpc_cidr     = "10.4.0.0/16"
    subnet_cidrs = ["10.4.1.0/24"]
  }

  # Check that our custom data source values are used
  assert {
    condition     = length(data.aws_availability_zones.available.names) == 3
    error_message = "Should have 3 availability zones from custom data"
  }

  assert {
    condition     = data.aws_availability_zones.available.names[0] == "us-east-1a"
    error_message = "First AZ should be us-east-1a from custom data"
  }

  assert {
    condition     = data.aws_availability_zones.available.zone_ids[0] == "use1-az1"
    error_message = "First zone ID should be use1-az1 from custom data"
  }
}