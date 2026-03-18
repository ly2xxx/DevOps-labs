# AWS CloudFormation & Service Catalog Cheatsheet

## 🚀 AWS CLI Commands

### CloudFormation

```bash
# Create a stack
aws cloudformation create-stack \
  --stack-name my-stack \
  --template-body file://template.yaml \
  --parameters ParameterKey=BucketName,ParameterValue=my-bucket

# Update a stack
aws cloudformation update-stack \
  --stack-name my-stack \
  --template-body file://template.yaml

# Delete a stack
aws cloudformation delete-stack --stack-name my-stack

# List all stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE

# Describe a stack
aws cloudformation describe-stacks --stack-name my-stack

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name my-stack \
  --query 'Stacks[0].Outputs'

# Validate template
aws cloudformation validate-template --template-body file://template.yaml

# Watch stack events in real-time
aws cloudformation describe-stack-events \
  --stack-name my-stack \
  --max-items 10
```

### Service Catalog

```bash
# List available products
aws servicecatalog search-products

# Describe a product
aws servicecatalog describe-product --id prod-xxxxx

# Provision a product
aws servicecatalog provision-product \
  --product-id prod-xxxxx \
  --provisioning-artifact-id pa-xxxxx \
  --provisioned-product-name my-provisioned-product

# List provisioned products
aws servicecatalog list-provisioned-products

# Terminate provisioned product
aws servicecatalog terminate-provisioned-product \
  --provisioned-product-id pp-xxxxx
```

## 📝 CloudFormation Template Structure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Template description'

# Optional: Metadata section
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: "Network Configuration"
        Parameters:
          - VPCCidr

# Optional: Input parameters
Parameters:
  ParameterName:
    Type: String
    Default: 'default-value'
    Description: 'Parameter description'
    AllowedValues:
      - value1
      - value2

# Optional: Mappings (like a lookup table)
Mappings:
  RegionMap:
    us-east-1:
      AMI: ami-xxxxx
    eu-west-1:
      AMI: ami-yyyyy

# Optional: Conditions
Conditions:
  IsProduction: !Equals [!Ref Environment, 'production']

# Required: Resources
Resources:
  MyResource:
    Type: 'AWS::ServiceName::ResourceType'
    Condition: IsProduction  # Optional
    Properties:
      PropertyName: !Ref ParameterName
      AnotherProperty: !FindInMap [RegionMap, !Ref 'AWS::Region', AMI]

# Optional: Outputs
Outputs:
  OutputName:
    Description: 'Output description'
    Value: !Ref MyResource
    Export:
      Name: ExportedValue
```

## 🔧 Intrinsic Functions

```yaml
# Reference a parameter or resource
!Ref ResourceName

# Get attribute from resource
!GetAtt ResourceName.AttributeName

# String substitution
!Sub 'My bucket is ${BucketName}'

# Join strings
!Join [':', [part1, part2, part3]]  # Returns: part1:part2:part3

# Select from list
!Select [0, !GetAZs '']  # First AZ in region

# Conditional
!If [ConditionName, ValueIfTrue, ValueIfFalse]

# Equals comparison
!Equals [!Ref Environment, 'production']

# Find in map
!FindInMap [MapName, TopLevelKey, SecondLevelKey]

# Get AZs
!GetAZs ''  # All AZs in current region
!GetAZs 'us-east-1'  # AZs in specific region

# Base64 encode (for UserData)
Fn::Base64: !Sub |
  #!/bin/bash
  echo "Hello"
```

## 🎯 Common Patterns

### Stack Dependencies (Exports/Imports)

**Stack A (exports):**
```yaml
Outputs:
  VPCId:
    Value: !Ref MyVPC
    Export:
      Name: !Sub '${AWS::StackName}-VPC'
```

**Stack B (imports):**
```yaml
Resources:
  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      SubnetId: !ImportValue other-stack-VPC
```

### Conditional Resources

```yaml
Parameters:
  CreateBucket:
    Type: String
    Default: 'true'
    AllowedValues: ['true', 'false']

Conditions:
  ShouldCreateBucket: !Equals [!Ref CreateBucket, 'true']

Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Condition: ShouldCreateBucket
```

### DependsOn (explicit dependency)

```yaml
Resources:
  MyEC2:
    Type: AWS::EC2::Instance
    DependsOn: MyDB  # Wait for DB before creating EC2
    Properties:
      # ...

  MyDB:
    Type: AWS::RDS::DBInstance
    Properties:
      # ...
```

### DeletionPolicy

```yaml
Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain  # Keep resource when stack is deleted
    # Options: Delete (default), Retain, Snapshot (RDS/EBS only)
```

## 🔐 IAM Best Practices

### CloudFormation Service Role

Create an IAM role that CloudFormation assumes to create resources:

```yaml
Resources:
  CloudFormationRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: cloudformation.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/PowerUserAccess
```

Then use it:
```bash
aws cloudformation create-stack \
  --stack-name my-stack \
  --template-body file://template.yaml \
  --role-arn arn:aws:iam::123456789012:role/CloudFormationRole
```

## 🐛 Troubleshooting

### Stack Creation Failed

```bash
# Check events
aws cloudformation describe-stack-events --stack-name my-stack

# Common issues:
# - Insufficient IAM permissions
# - Resource name conflicts
# - Invalid parameter values
# - Dependency errors
```

### Stack Stuck in UPDATE_ROLLBACK_FAILED

```bash
# Continue rollback (skip failed resources)
aws cloudformation continue-update-rollback --stack-name my-stack

# Or delete and recreate
aws cloudformation delete-stack --stack-name my-stack
```

### Debug Template Locally

```bash
# Validate syntax
aws cloudformation validate-template --template-body file://template.yaml

# Use cfn-lint for advanced validation
pip install cfn-lint
cfn-lint template.yaml

# Use rain for enhanced AWS CloudFormation CLI
brew install rain  # or download from GitHub
rain deploy template.yaml my-stack
```

## 📊 Resource Types Reference

### Common Free Tier Resources

```yaml
# S3 Bucket
AWS::S3::Bucket

# EC2 Instance
AWS::EC2::Instance

# VPC
AWS::EC2::VPC

# Subnet
AWS::EC2::Subnet

# Security Group
AWS::EC2::SecurityGroup

# RDS Database
AWS::RDS::DBInstance

# Lambda Function
AWS::Lambda::Function

# DynamoDB Table
AWS::DynamoDB::Table

# IAM Role
AWS::IAM::Role

# CloudWatch Log Group
AWS::Logs::LogGroup
```

## 🎓 Learning Resources

- **Official Docs:** https://docs.aws.amazon.com/cloudformation/
- **Template Reference:** https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-reference.html
- **Sample Templates:** https://github.com/awslabs/aws-cloudformation-templates
- **AWS Quick Starts:** https://aws.amazon.com/quickstart/
- **cfn101 Workshop:** https://cfn101.solution.builders/

## 💰 Cost Monitoring

```bash
# CloudFormation itself is free, but resources cost money
# Use AWS Cost Explorer to track spending

# Tag everything for cost allocation
Resources:
  MyResource:
    Type: AWS::S3::Bucket
    Properties:
      Tags:
        - Key: Project
          Value: MyApp
        - Key: CostCenter
          Value: Engineering
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy CloudFormation
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - name: Deploy
        run: |
          aws cloudformation deploy \
            --template-file template.yaml \
            --stack-name my-stack \
            --capabilities CAPABILITY_IAM
```

---

**Quick Reference Card:** Print this and keep it handy! 📋
