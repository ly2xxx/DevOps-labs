# Solution: TFLint Exercise

## Issues Found and Fixed

### 1. Resource Name: camelCase → snake_case
**Before:** `aws_s3_bucket "MyBucket"`  
**After:** `aws_s3_bucket "my_bucket"`

### 2. Deprecated Attribute: acl
**Before:**
```hcl
acl = "private"
```
**After:** Removed (S3 ACLs are deprecated; use bucket policies instead)

### 3. Missing Tags on S3 Bucket
**Before:** No tags  
**After:**
```hcl
tags = {
  Environment = "test"
  ManagedBy   = "terraform"
}
```

### 4. Missing Tags on EC2 Instance
**Before:** No tags  
**After:**
```hcl
tags = {
  Name = "web-server"
}
```

### 5. EC2 Instance Type
**Before:** `t2.micro` (older)  
**After:** `t3.micro` (recommended)

## Fixed main.tf

```hcl
provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-intentional-bucket-name"

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name = "web-server"
  }
}
```

## Run TFLint to Verify

```bash
cd exercise-8-tflint-local
tflint
```

Should return: `No issues found!`
