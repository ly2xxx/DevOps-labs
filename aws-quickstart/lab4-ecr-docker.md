# Lab 4: ECR (Elastic Container Registry) - Docker Image Registry

**Time to complete: ~30 minutes | Cost: Free tier (500MB storage/month for 1 year)**

## 🎯 What You'll Learn

- Create a private Docker registry with CloudFormation
- Build and push Docker images to ECR
- Use ECR lifecycle policies to manage storage costs
- Enable automatic vulnerability scanning
- Pull images from ECR to run containers

## 📋 Prerequisites

Before starting, ensure you have:

1. **Docker Desktop installed** (or Docker CLI)
   - Windows/Mac: https://www.docker.com/products/docker-desktop
   - Linux: `sudo apt install docker.io` or `yum install docker`
   - Verify: `docker --version`

2. **AWS CLI installed and configured**
   - Install: https://aws.amazon.com/cli/
   - Configure: `aws configure` (enter your access key, secret key, region)
   - Verify: `aws sts get-caller-identity`

3. **Appropriate IAM permissions:**
   - `AmazonEC2ContainerRegistryFullAccess` (or equivalent)
   - `CloudFormationFullAccess`
   ```bash
   aws iam list-attached-user-policies --user-name YOUR_USERNAME

   aws iam list-groups-for-user --user-name YOUR_USERNAME

   aws iam list-attached-group-policies --group-name YOUR_GROUP_NAME
   ```
   - If you see AdministratorAccess listed, you already have full permissions for everything in AWS, and you are good to go!
   - If you don't see AdministratorAccess, look for AmazonEC2ContainerRegistryFullAccess and AWSCloudFormationFullAccess.
   - If none of those are there, you (or your admin) will need to attach the policies to the group using:
   ```bash
   aws iam attach-group-policy --group-name YOUR_GROUP_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

   aws iam attach-group-policy --group-name YOUR_GROUP_NAME --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess
   ```

## 🚀 Lab Steps

### Step 1: Create a Simple Docker Application (5 min)

First, let's create a simple web app to containerize.

1. **Create a project directory:**

```bash
mkdir ecr-lab
cd ecr-lab
```

2. **Create a simple web server (app.py):**

```bash
# For Windows PowerShell:
@"
from http.server import HTTPServer, BaseHTTPRequestHandler

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        message = '''
        <html>
          <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>🐳 ECR Lab - Hello from Docker!</h1>
            <p>This container was pulled from AWS ECR</p>
            <p>Image built on: <code>v1.0</code></p>
          </body>
        </html>
        '''
        self.wfile.write(message.encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), SimpleHandler)
    print('Server running on port 8080...')
    server.serve_forever()
"@ | Out-File -Encoding UTF8 app.py
```

```bash
# For Linux/Mac:
cat > app.py << 'EOF'
from http.server import HTTPServer, BaseHTTPRequestHandler

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        message = '''
        <html>
          <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>🐳 ECR Lab - Hello from Docker!</h1>
            <p>This container was pulled from AWS ECR</p>
            <p>Image built on: <code>v1.0</code></p>
          </body>
        </html>
        '''
        self.wfile.write(message.encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), SimpleHandler)
    print('Server running on port 8080...')
    server.serve_forever()
EOF
```

3. **Create Dockerfile:**

```bash
# Windows PowerShell:
@"
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python", "app.py"]
"@ | Out-File -Encoding UTF8 Dockerfile
```

```bash
# Linux/Mac:
cat > Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python", "app.py"]
EOF
```

4. **Test locally (optional):**

```bash
docker build -t my-app:latest .
docker run -p 8080:8080 my-app:latest
# Open browser: http://localhost:8080
# Press Ctrl+C to stop
```

---

### Step 2: Deploy ECR Repository with CloudFormation (5 min)

1. **Deploy the CloudFormation stack:**
   - Go to: https://console.aws.amazon.com/cloudformation
   - Click **Create stack** → **With new resources**
   - Upload `lab4-ecr-docker.yaml`
   - Stack name: `ecr-lab-stack`
   - Parameters:
     - RepositoryName: `my-app-repo` (or customize)
     - EnableImageScanning: `true` (recommended for security)
     - MaxImageCount: `5` (keeps storage costs low)
   - Click **Next** → **Next** → **Submit**

2. **Wait for CREATE_COMPLETE** (~1-2 minutes)

3. **Capture important outputs:**
   - Go to **Outputs** tab
   - Copy the **RepositoryUri** (looks like: `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo`)
   - Copy the **DockerLoginCommand**

---

### Step 3: Authenticate Docker with ECR (2 min)

ECR uses IAM authentication. You need to log in Docker before pushing.

1. **Run the login command** (from CloudFormation Outputs):
   ```bash
   # Example (your region/account will differ):
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
   ```

2. **Expected output:**
   ```
   Login Succeeded
   ```

> **Note:** This token expires after 12 hours. If you get authentication errors later, re-run this command.

---

### Step 4: Build, Tag, and Push Your Docker Image (5 min)

1. **Build the image:**
   ```bash
   cd ecr-lab  # Make sure you're in the directory with Dockerfile
   docker build -t my-app-repo:latest .
   ```

2. **Tag the image for ECR:**
   ```bash
   # Replace with YOUR RepositoryUri from CloudFormation Outputs
   docker tag my-app-repo:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:latest
   ```

3. **Push to ECR:**
   ```bash
   docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:latest
   ```

4. **Watch the upload:**
   ```
   The push refers to repository [123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo]
   abc123def456: Pushed
   latest: digest: sha256:... size: 1234
   ```

**🎉 Success!** Your image is now stored in ECR.

---

### Step 5: View Image in ECR Console (3 min)

1. **Open ECR Console:**
   - Go to: https://console.aws.amazon.com/ecr
   - Click on **Repositories** → **my-app-repo**

2. **Explore the interface:**
   - **Images tab:** See your `latest` tag with size, push date, digest
   - **Vulnerabilities tab:** If scanning enabled, check for security issues
   - **Lifecycle policy:** See the rule that keeps only 5 images

3. **Check vulnerability scan results** (if enabled):
   - Click on the image digest
   - View **Scan results** (may take 1-2 minutes to complete)
   - See severity breakdown (Critical, High, Medium, Low)

---

### Step 6: Pull and Run Image from ECR (5 min)

Now let's simulate deploying this image elsewhere (e.g., on an EC2 instance or ECS).

1. **Delete local image** (to prove we're pulling from ECR):
   ```bash
   docker rmi my-app-repo:latest
   docker rmi 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:latest
   ```

2. **Pull from ECR:**
   ```bash
   docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:latest
   ```

3. **Run the container:**
   ```bash
   docker run -d -p 8080:8080 --name ecr-test 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:latest
   ```

4. **Test it works:**
   - Open browser: http://localhost:8080
   - You should see "Hello from Docker!" page

5. **Stop and remove:**
   ```bash
   docker stop ecr-test
   docker rm ecr-test
   ```

---

### Step 7: Push Multiple Versions (Bonus - 5 min)

Test the lifecycle policy by pushing multiple tagged versions.

1. **Create v1.1:**
   ```bash
   # Edit app.py to show "v1.1" instead of "v1.0"
   # Then:
   docker build -t my-app-repo:v1.1 .
   docker tag my-app-repo:v1.1 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:v1.1
   docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:v1.1
   ```

2. **Create v1.2, v1.3, v1.4, v1.5, v1.6:**
   - Repeat the process 5 more times (or script it)
   - Push at least 6 images total

3. **Check ECR Console:**
   - Go to **Images** tab
   - Notice **only 5 images remain** (oldest auto-deleted by lifecycle policy!)
   - This keeps your storage costs under control

---

### Step 8: Cleanup (2 min)

**Important:** ECR charges for storage, so delete when done practicing.

1. **Delete all images first:**
   - ECR Console → Select repository → **Delete all images**
   - Or via CLI:
     ```bash
     aws ecr batch-delete-image \
       --repository-name my-app-repo \
       --image-ids imageTag=latest imageTag=v1.1 imageTag=v1.2
     ```

2. **Delete CloudFormation stack:**
   - CloudFormation Console → Select `ecr-lab-stack` → **Delete**
   - This deletes the repository (only works if images are already deleted)

---

## 🧠 Key Concepts Explained

### ECR Repository
- **Private by default** - requires AWS authentication
- **Regional** - exists in one AWS region (e.g., us-east-1)
- **Immutable tags (optional)** - prevent `latest` tag from being overwritten

### Image Scanning
- **On-push scanning** - automatic vulnerability check when you push
- **Uses Amazon Inspector** - checks against CVE database
- **Free tier included** - no extra cost for basic scanning

### Lifecycle Policies
- **Automate cleanup** - delete old/unused images
- **Rules-based** - e.g., "keep last 5 images" or "delete images older than 30 days"
- **Saves money** - prevents storage bloat

### Authentication Flow
```
┌──────────────┐
│  AWS CLI     │  → Get 12-hour token via IAM
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  docker login│  → Uses token to authenticate
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  docker push │  → Uploads image layers over HTTPS
└──────────────┘
```

---

## 💡 Real-World Use Cases

### 1. **CI/CD Pipeline**
```bash
# In your GitHub Actions / Jenkins:
- Build Docker image
- Tag with git commit SHA
- Push to ECR
- Deploy to ECS/EKS using that specific tag
```

### 2. **Multi-Environment Strategy**
```
my-app-repo:dev-v1.0    → Development environment
my-app-repo:staging-v1.0 → Staging environment
my-app-repo:prod-v1.0   → Production environment
```

### 3. **Lambda Container Images**
- ECR supports up to 10GB images
- Lambda can run containers directly from ECR
- Perfect for ML models, heavy dependencies

---

## 🎓 CloudFormation Template Breakdown

### Key Resources Created

1. **AWS::ECR::Repository**
   - Core registry resource
   - Properties:
     - `ImageScanningConfiguration`: Enables CVE scanning
     - `ImageTagMutability`: MUTABLE allows tag overwrites
     - `EncryptionConfiguration`: AES-256 encryption at rest
     - `LifecyclePolicy`: Auto-delete old images

2. **LifecyclePolicy (Embedded JSON)**
   ```yaml
   rules:
     - Keep only N most recent images
     - Delete older images automatically
     - Runs daily
   ```

### Important Outputs

- **RepositoryUri**: The full registry path for docker commands
- **DockerLoginCommand**: Ready-to-paste authentication command
- **ConsoleURL**: Direct link to view in AWS Console

---

## 🚨 Free Tier Limits

✅ **Included in Free Tier (first 12 months):**
- 500 MB storage per month
- Scanning on push (basic)

⚠️ **After Free Tier / Above Limits:**
- $0.10/GB/month for storage
- $0.09/GB for data transfer out to internet
- Data transfer within AWS region: FREE

**Example:** Storing 10 Docker images (~2GB total) = ~$0.20/month

---

## 🆘 Troubleshooting

### "no basic auth credentials" error
**Problem:** Docker not authenticated with ECR  
**Solution:** Re-run the login command:
```bash
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
```

### "denied: Your authorization token has expired"
**Problem:** ECR tokens expire after 12 hours  
**Solution:** Same as above - get a new token

### "DELETE_FAILED: Repository not empty"
**Problem:** Can't delete ECR repository with CloudFormation if images exist  
**Solution:** Delete all images first (via Console or CLI), then delete stack

### Image push is very slow
**Problem:** Slow upload speed  
**Solution:**
- Check your internet connection
- Use a closer AWS region
- Build multi-stage Dockerfiles to reduce image size

### Vulnerability scan shows "CRITICAL" findings
**Problem:** Base image has known vulnerabilities  
**Solution:**
- Update base image to latest version (e.g., `python:3.11-slim` → `python:3.12-slim`)
- Use distroless images (e.g., `gcr.io/distroless/python3`)
- Review and patch vulnerabilities in your dependencies

---

## 📖 Next Steps

After completing this lab, try:

1. **Cross-region replication:**
   - Enable ECR replication to backup images to another region
   - Useful for disaster recovery

2. **Private link integration:**
   - Access ECR from VPC without internet gateway
   - Improves security and reduces data transfer costs

3. **ECS/EKS integration:**
   - Deploy your ECR image to Elastic Container Service
   - Or run on Kubernetes with EKS

4. **Advanced lifecycle policies:**
   - Keep images tagged with "prod-*" indefinitely
   - Delete untagged images after 7 days
   - Combine multiple rules

5. **Cross-account sharing:**
   - Share ECR images with other AWS accounts
   - Useful for multi-account organizations

---

## 📚 Additional Resources

- **ECR User Guide:** https://docs.aws.amazon.com/ecr/
- **Docker Documentation:** https://docs.docker.com/
- **ECR Pricing:** https://aws.amazon.com/ecr/pricing/
- **Container Security Best Practices:** https://aws.amazon.com/blogs/containers/

---

**🎉 Congratulations!** You've successfully:
- Created a private Docker registry with CloudFormation
- Built and pushed a containerized application
- Enabled vulnerability scanning
- Implemented automated image lifecycle management

This is the foundation for modern container-based deployments on AWS! 🚀
