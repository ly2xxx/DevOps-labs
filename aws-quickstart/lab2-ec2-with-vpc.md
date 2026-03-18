# Lab 2: EC2 Instance with VPC - Explanation

This CloudFormation template (`lab2-ec2-with-vpc.yaml`) sets up a complete, secure environment for a web server, including a Virtual Private Cloud (VPC), public subnet, internet access, and an EC2 instance configured as a web server.

## Line-by-Line Breakdown

### 1. Template Metadata (Lines 1-2)
*   **Line 1:** `AWSTemplateFormatVersion: '2010-09-09'` – Defines the CloudFormation version (currently only this version exists).
*   **Line 2:** `Description: ...` – A text string describing the purpose of the template.

---

### 2. Parameters (Lines 4-25)
Parameters allow you to input values at runtime (when you create the stack).
*   **Lines 5–13 (`InstanceType`):** Defines the hardware size of the EC2 instance.
    *   **Line 8:** `Default: t2.micro` – The suggested type if you don't pick one.
    *   **Lines 9–12:** `AllowedValues` – Limits choices to Free Tier eligible types.
*   **Lines 15–18 (`KeyName`):** Asks for an existing EC2 Key Pair name so you can SSH into the instance.
*   **Lines 20–25 (`SSHLocation`):** Defines which IP addresses can connect via SSH. Defaults to `0.0.0.0/0` (everyone), but uses a Regex (`AllowedPattern`) to ensure a valid CIDR format.

---

### 3. Mappings (Lines 28-38)
*   **Lines 28–37 (`RegionMap`):** A lookup table for Amazon Machine Image (AMI) IDs. Since AMI IDs are unique to each AWS Region (e.g., `us-east-1` vs `us-west-2`), this ensures the template works across different regions by selecting the correct "Amazon Linux 2023" ID based on where you deploy.

---

### 4. Resources: Networking (Lines 40-100)
This section builds the "house" for your server.
*   **Lines 42–50 (`MyVPC`):** Creates the Virtual Private Cloud.
    *   **Line 45:** `CidrBlock: 10.0.0.0/16` – Defines the internal IP range (65,536 possible IPs).
    *   **Lines 46–47:** Enables DNS so your instances get human-readable names.
*   **Lines 53–64 (`InternetGateway` & `AttachGateway`):** Creates a "door" to the internet and attaches it to the VPC so traffic can flow in and out.
*   **Lines 67–76 (`PublicSubnet`):** Carves out a smaller section of the VPC (`10.0.1.0/24`).
    *   **Line 72:** `!Select [0, !GetAZs '']` – Automatically picks the first Availability Zone in the region.
    *   **Line 73:** `MapPublicIpOnLaunch: true` – Ensures any instance launched here gets a public IP.
*   **Lines 79–94 (`PublicRouteTable` & `PublicRoute`):** The "GPS" of the network.
    *   **Line 92:** `DestinationCidrBlock: 0.0.0.0/0` – Targets all traffic.
    *   **Line 93:** `GatewayId: !Ref InternetGateway` – Directs that traffic out through the Internet Gateway created earlier.
*   **Lines 95–99 (`SubnetRouteTableAssociation`):** Links the routing rules to the specific subnet.

---

### 5. Resources: Security Group (Lines 102-126)
This is the virtual firewall for the instance.
*   **Lines 107–113 (SSH Inbound):** Opens Port 22 for SSH access from the IP range defined in `SSHLocation`.
*   **Lines 114–119 (HTTP Inbound):** Opens Port 80 for web traffic from anywhere (`0.0.0.0/0`).
*   **Lines 120–123 (Egress):** Allows the server to talk back to the internet (e.g., to download updates).

---

### 6. Resources: EC2 Instance (Lines 129-180)
This is the actual virtual server.
*   **Line 132:** Uses the `InstanceType` parameter.
*   **Line 134:** `!FindInMap` – Looks up the correct AMI ID from the mapping section based on the current region (`AWS::Region`).
*   **Lines 138–175 (`UserData`):** A script that runs automatically when the server first starts:
    *   **Line 142:** Updates software.
    *   **Line 145:** Installs the Apache Web Server (`httpd`).
    *   **Lines 148–149:** Starts the web server.
    *   **Lines 152–174:** Creates a custom HTML landing page (`index.html`) using local metadata (like the Stack Name and Region) to confirm the lab is successful.

---

### 7. Outputs (Lines 182-214)
Information shown in the AWS Console after the template finishes.
*   **Line 185:** Shows the unique Instance ID.
*   **Line 189:** Shows the Public IP.
*   **Line 197:** Provides a clickable link (`http://...`) to view your web page.
*   **Line 201:** Provides a ready-to-use SSH command for your terminal.
*   **Lines 203–214:** Exports the VPC and Security Group IDs so they can be referenced by *other* CloudFormation stacks in the future.
