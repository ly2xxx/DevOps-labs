# Lab 5: AWS Fargate - Serverless Containers (No EC2 to Manage)

**Time to complete: ~45 minutes | Cost: ~$0.60/hour (delete stack when done!)**

## 🎯 What You'll Learn

- **AWS Fargate fundamentals**: Serverless container compute
- **ECS (Elastic Container Service)**: AWS container orchestration
- **When to use Fargate vs EC2**: Cost and complexity trade-offs
- **Application Load Balancer**: Distribute traffic across containers
- **Container networking**: VPC, security groups, target groups
- **CloudWatch Logs**: Monitor container output

## 📋 Prerequisites

Before starting, ensure you have:

1. **AWS Account** with free tier or credits
2. **AWS CLI configured** (optional but helpful)
   ```powershell
   aws configure
   # Enter access key, secret key, region (us-east-1 recommended)
   ```

3. **Basic Docker knowledge** (what containers are)
4. **Completed Lab 4 (ECR)** - helpful but not required

---

## 📚 Background: What is Fargate?

### The Problem with EC2 for Containers

**Traditional approach (EC2-based ECS):**
```
You → Provision EC2 instances
     → Install container runtime
     → Configure auto-scaling
     → Manage OS patches
     → Monitor instance health
     → Pay for instances even if underutilized
```

**Fargate approach (serverless):**
```
You → Define container requirements
     → AWS handles everything else
     → Pay only for what you use (per-second billing)
```

---

### Fargate vs EC2 Comparison

| Factor | Fargate | EC2-based ECS |
|--------|---------|---------------|
| **Management** | Zero server management | Manage EC2 fleet |
| **Pricing** | Pay per vCPU-second + GB-second | Pay for EC2 instances (even if idle) |
| **Startup time** | ~30-60 seconds | Depends on AMI/size |
| **Flexibility** | Fixed CPU/memory combinations | Any instance type |
| **Cost (small workload)** | Lower (pay for use) | Higher (idle time waste) |
| **Cost (large steady workload)** | Higher | Lower (economies of scale) |
| **Use case** | Microservices, batch jobs, dev/test | Long-running, predictable workloads |

**Rule of thumb:**
- **Use Fargate**: Bursty workloads, microservices, don't want to manage servers
- **Use EC2**: Large, steady workloads where you can optimize instance sizing

---

## 🏗️ What This Lab Builds

```
                Internet
                   │
                   ▼
        ┌─────────────────────┐
        │ Application Load    │
        │ Balancer (ALB)      │
        │ Port 80             │
        └─────────┬───────────┘
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
┌────────────┐          ┌────────────┐
│ Fargate    │          │ Fargate    │
│ Task 1     │          │ Task 2     │
│ (NGINX)    │          │ (NGINX)    │
└────────────┘          └────────────┘
      │                       │
      └───────────┬───────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │ CloudWatch Logs     │
        │ (Container output)  │
        └─────────────────────┘
```

**Resources created:**
- 1 VPC with 2 public subnets (high availability)
- 1 Internet Gateway
- 2 Security Groups (ALB + Tasks)
- 1 Application Load Balancer
- 1 ECS Cluster (Fargate type)
- 1 Task Definition (container spec)
- 1 ECS Service (manages tasks)
- 1 CloudWatch Log Group

---

## 🚀 Lab Steps

### Step 1: Review the Template (5 minutes)

Open `lab5-fargate-ecs.yaml` and notice:

**Key sections:**
```yaml
# Networking (VPC, Subnets, IGW, Routes)
VPC:
  Type: AWS::EC2::VPC
  Properties:
    CidrBlock: 10.0.0.0/16

# Security Groups (ALB can talk to internet, Tasks only accept from ALB)
ALBSecurityGroup:
  # Allows HTTP from anywhere

TaskSecurityGroup:
  # Only allows traffic from ALB

# ECS Cluster (Fargate capacity provider)
ECSCluster:
  Type: AWS::ECS::Cluster
  Properties:
    CapacityProviders:
      - FARGATE
      - FARGATE_SPOT  # Cheaper spot instances

# Task Definition (defines the container)
TaskDefinition:
  Type: AWS::ECS::TaskDefinition
  Properties:
    NetworkMode: awsvpc  # Required for Fargate
    Cpu: '256'  # 0.25 vCPU
    Memory: '512'  # 0.5 GB
    ContainerDefinitions:
      - Name: fargate-web-app
        Image: public.ecr.aws/docker/library/nginx:alpine

# Service (maintains desired number of running tasks)
ECSService:
  Type: AWS::ECS::Service
  Properties:
    DesiredCount: 2
    LaunchType: FARGATE
```

**Key concept**: The service ensures 2 tasks are always running. If one crashes, it's automatically replaced!

---

### Step 2: Deploy the Stack (10 minutes)

**1. Go to CloudFormation console:**
```
https://console.aws.amazon.com/cloudformation
```

**2. Create stack:**
- Click **Create stack** → **With new resources**
- **Template source**: Upload a template file
- Choose `lab5-fargate-ecs.yaml`
- Click **Next**

**3. Configure stack:**
- **Stack name**: `fargate-demo`
- **ServiceName**: `fargate-web-app` (default is fine)
- **ContainerImage**: `public.ecr.aws/docker/library/nginx:alpine` (default)
- **ContainerPort**: `80`
- **DesiredCount**: `2` (two tasks for high availability)
- **TaskCpu**: `256` (0.25 vCPU - smallest/cheapest)
- **TaskMemory**: `512` (0.5 GB - smallest allowed with 256 CPU)
- Click **Next**

**4. Configure stack options:**
- Tags (optional): Add `Environment: Lab`
- Click **Next**

**5. Review:**
- Scroll to bottom
- Check ☑ **I acknowledge that AWS CloudFormation might create IAM resources**
- Click **Submit**

**6. Wait for CREATE_COMPLETE (~8-10 minutes)**

CloudFormation will create resources in this order:
1. VPC and networking (2 min)
2. Security groups (30 sec)
3. Load balancer (2 min)
4. ECS cluster (30 sec)
5. IAM roles (30 sec)
6. Task definition (instant)
7. ECS service (3-4 min - downloads image, starts tasks)

**Watch the Events tab** to see progress.

---

### Step 3: Access Your Application (2 minutes)

**1. Get the Load Balancer URL:**
- Go to **Outputs** tab in CloudFormation
- Copy **LoadBalancerURL** (looks like: `http://fargate-demo-ALB-123456.us-east-1.elb.amazonaws.com`)

**2. Open in browser:**
- Paste URL in browser
- You should see: **"Welcome to nginx!"**

**3. Verify load balancing:**
```powershell
# Hit the endpoint multiple times
for ($i=1; $i -le 10; $i++) {
    curl http://fargate-demo-ALB-123456.us-east-1.elb.amazonaws.com
    Start-Sleep -Seconds 1
}
```

Traffic is distributed across 2 Fargate tasks!

---

### Step 4: Explore ECS Console (10 minutes)

**1. Go to ECS console:**
```
https://console.aws.amazon.com/ecs
```

**2. Click on your cluster** (`fargate-demo-cluster`)

**3. Explore sections:**

**Services tab:**
- See `fargate-web-app` service
- Click on it
- **Desired tasks**: 2
- **Running tasks**: 2
- **Task definition**: fargate-demo-task:1

**Tasks tab:**
- See 2 running tasks
- Click on one task
- **Status**: RUNNING
- **Platform version**: LATEST
- **Connectivity**: PUBLIC (has public IP)
- **Containers section**: See nginx container

**4. View container logs:**
- In task details, click **Logs** tab
- See NGINX access logs
- Every time you hit the URL, you'll see log entries!

**5. Try stopping a task:**
- Go back to **Tasks** tab
- Select one task
- Click **Stop**
- Confirm

**Watch what happens:**
- Task enters STOPPING status
- Within 30-60 seconds, a NEW task starts (service maintains desired count!)
- This is **self-healing** - Fargate automatically replaces failed tasks

---

### Step 5: View CloudWatch Logs (5 minutes)

**1. Go to CloudWatch console:**
```
https://console.aws.amazon.com/cloudwatch
```

**2. Navigate:**
- Left menu → **Logs** → **Log groups**
- Find `/ecs/fargate-demo`
- Click on it

**3. Explore log streams:**
- See one log stream per task (each has unique ID)
- Click on a stream
- See all container output (NGINX logs)

**4. Search logs:**
```
# In the log events view, try filter patterns:
GET

# Or search for specific IPs:
[your_ip_address]
```

**5. Create metric filter (optional):**
- Click **Create metric filter**
- Pattern: `GET`
- Test pattern → See matches
- This is how you'd create custom metrics from logs!

---

### Step 6: Scale the Service (5 minutes)

**Method 1: Via ECS Console**
```
1. ECS → Clusters → fargate-demo-cluster
2. Services → fargate-web-app
3. Click "Update service"
4. Change "Desired tasks" to 3
5. Click "Update"
```

Watch tasks tab - a 3rd task starts!

**Method 2: Via CloudFormation (Infrastructure as Code)**
```
1. CloudFormation console
2. Select fargate-demo stack
3. Click "Update"
4. Choose "Use current template"
5. Next
6. Change DesiredCount to 3
7. Next → Next → Submit
```

CloudFormation updates the service!

**Method 3: Via AWS CLI**
```powershell
aws ecs update-service \
  --cluster fargate-demo-cluster \
  --service fargate-web-app \
  --desired-count 3
```

**Verify:**
```powershell
aws ecs describe-services \
  --cluster fargate-demo-cluster \
  --services fargate-web-app \
  --query 'services[0].desiredCount'
```

---

### Step 7: Update the Container Image (5 minutes)

Let's deploy a custom NGINX page!

**1. Create simple HTML:**
```powershell
# We'll use a different public image with custom content
# Or build your own (requires ECR from Lab 4)
```

**2. Update stack:**
- CloudFormation → Select fargate-demo
- **Update**
- **Use current template**
- Change `ContainerImage` to: `public.ecr.aws/docker/library/httpd:alpine`
  - This switches from NGINX to Apache
- **Next** → **Next** → **Submit**

**3. Watch the deployment:**
- ECS Console → Service → Deployments tab
- You'll see **2 deployments**:
  - PRIMARY (new): httpd:alpine
  - ACTIVE (old): nginx:alpine
- ECS drains traffic from old tasks, spins up new ones
- **Zero-downtime deployment!**

**4. Verify:**
- Hit the ALB URL again
- Now see: **"It works!"** (Apache default page)

---

## 💡 Key Concepts Explained

### 1. Task Definition vs Service

**Task Definition** = Blueprint (like a Docker Compose file)
```yaml
- Which image?
- How much CPU/memory?
- Which ports?
- Environment variables?
- Logging config?
```

**Service** = Runtime manager
```yaml
- How many tasks to run? (desired count)
- Where to run them? (subnets)
- How to route traffic? (load balancer)
- What to do if task fails? (restart it)
```

**Analogy:** Recipe (Task Definition) vs. Chef (Service)

---

### 2. awsvpc Network Mode

Fargate requires `NetworkMode: awsvpc`:
- Each task gets its own **Elastic Network Interface (ENI)**
- Each task has its own **private IP** (and optionally public IP)
- Tasks are first-class citizens in your VPC
- Security groups apply **per-task**, not per host

**Benefit:** Fine-grained network security, just like EC2 instances.

---

### 3. Target Type: IP vs Instance

For Fargate, ALB target group **must use `TargetType: ip`**:
```yaml
TargetGroup:
  Properties:
    TargetType: ip  # Not 'instance' like EC2-based ECS
```

**Why:** Fargate tasks don't run on EC2 instances you control. They get dynamic IPs.

---

### 4. Fargate Pricing Model

**Charged for:**
- vCPU-seconds
- GB-seconds (memory)

**Example (our lab):**
```
Task: 0.25 vCPU + 0.5 GB RAM
Price: $0.04048/vCPU-hour + $0.004445/GB-hour

Per task per hour:
  (0.25 × $0.04048) + (0.5 × $0.004445) = $0.01234

2 tasks × 1 hour = $0.02468/hour
2 tasks × 24 hours = $0.59/day
2 tasks × 30 days = $17.76/month
```

**Plus ALB costs:** ~$16/month

**Total if left running 24/7:** ~$34/month

**💡 Cost-saving tip:** Use FARGATE_SPOT (50% cheaper) for non-critical workloads!

---

## 🆚 Fargate vs Other AWS Compute

| Service | Best For | Example Use Case |
|---------|----------|------------------|
| **Fargate** | Short-lived containers, microservices | API backend, batch jobs |
| **EC2 ECS** | Long-running containers at scale | 24/7 web app with stable traffic |
| **Lambda** | Event-driven functions (<15 min) | Image resizing, API endpoints |
| **EC2** | Full control, complex workloads | Databases, legacy apps |
| **Batch** | Large-scale batch processing | Data transformation, ML training |

---

## 🔧 Advanced: Custom Container

Want to deploy your own container? Here's how:

**1. Build image** (requires Docker):
```dockerfile
# Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
```

```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<body>
  <h1>Hello from Fargate!</h1>
  <p>Running on AWS Fargate - no servers to manage!</p>
</body>
</html>
```

**2. Push to ECR** (from Lab 4):
```powershell
# Build
docker build -t my-web-app .

# Tag for ECR
docker tag my-web-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest

# Push
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest
```

**3. Update task definition:**
```yaml
ContainerImage: <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest
```

**4. Redeploy** via CloudFormation update.

---

## 📊 Monitoring Best Practices

### CloudWatch Metrics (Automatic)

Fargate provides these metrics:
- **CPUUtilization**: Task CPU usage %
- **MemoryUtilization**: Task memory usage %
- **DesiredTaskCount**: How many tasks should be running
- **RunningTaskCount**: How many are actually running

**View:**
```
ECS Console → Cluster → Metrics tab
```

### CloudWatch Alarms (Recommended)

Create alarms for:
```yaml
# High CPU (scaling indicator)
CPUUtilization > 80% for 2 minutes

# No running tasks (outage!)
RunningTaskCount < DesiredTaskCount for 5 minutes

# Memory pressure
MemoryUtilization > 90% for 2 minutes
```

### Container Insights (Optional, Extra Cost)

Enable for detailed metrics:
```powershell
aws ecs put-account-setting \
  --name containerInsights \
  --value enabled
```

Gives you per-container metrics, network stats, etc.

---

## 🧹 Cleanup (IMPORTANT!)

**Fargate charges accrue while running.** Delete when done:

**Method 1: CloudFormation (Recommended)**
```
1. CloudFormation Console
2. Select fargate-demo stack
3. Delete
4. Confirm

CloudFormation deletes ALL resources (ECS, ALB, VPC, etc.)
```

**Method 2: AWS CLI**
```powershell
aws cloudformation delete-stack --stack-name fargate-demo
```

**Verify deletion:**
```powershell
# Check stack status
aws cloudformation describe-stacks --stack-name fargate-demo

# Should show: DELETE_COMPLETE
```

**What gets deleted:**
- ECS Service (stops all tasks)
- ECS Cluster
- Task Definition
- Load Balancer
- Target Group
- Security Groups
- Subnets
- Internet Gateway
- VPC
- CloudWatch Log Group
- IAM Roles

**Billing stops** as soon as tasks are stopped (within 1-2 minutes).

---

## 🎓 Key Takeaways

✅ **Fargate = Serverless containers** - no EC2 to manage  
✅ **Pay per second** - only for what you use  
✅ **Auto-scaling built-in** - service maintains desired count  
✅ **Zero-downtime deployments** - rolling updates with ALB  
✅ **CloudWatch integration** - logs and metrics included  
✅ **awsvpc networking** - tasks are first-class VPC citizens  

**When to use Fargate:**
- Microservices architecture
- Unpredictable/bursty traffic
- Development and testing
- Don't want to manage infrastructure

**When NOT to use Fargate:**
- Need GPU access (use EC2)
- Very large, consistent workload (EC2 cheaper at scale)
- Need < 0.25 vCPU (Lambda is better)
- Require host-level access or custom AMI

---

## 📖 Next Steps

After completing this lab, explore:

1. **Auto-scaling**: Add Application Auto Scaling for Fargate
2. **Service Discovery**: Use AWS Cloud Map for service-to-service communication
3. **Blue/Green Deployments**: CodeDeploy for Fargate
4. **Fargate Spot**: Use spot capacity for 50% cost savings
5. **Private subnets**: Move tasks to private subnets with NAT Gateway
6. **Secrets Management**: Use AWS Secrets Manager for sensitive data
7. **Multiple containers per task**: Sidecar patterns (logging, proxy)

---

## 🆘 Troubleshooting

### Issue: Tasks keep stopping/restarting

**Check:**
```
ECS → Cluster → Tasks → Click stopped task → Stopped reason
```

**Common causes:**
- Container exits immediately (check logs)
- Health check fails (increase `HealthCheckGracePeriodSeconds`)
- Out of memory (increase `TaskMemory`)
- Image pull failed (check image URL, ECR permissions)

---

### Issue: Can't access ALB URL

**Check:**
1. **ALB security group** allows port 80 from 0.0.0.0/0
2. **Tasks are running** (not stuck in PENDING)
3. **Target group health**: ECS Console → Target Groups → Targets tab
   - Should show "healthy"
4. **DNS propagation**: Wait 2-3 minutes after stack creation

---

### Issue: Stack creation failed

**Common errors:**
```
# Insufficient capacity
Error: Could not launch task

Fix: Try different region or wait a few minutes

# Image pull failed
Error: CannotPullContainerError

Fix: Check image URL, ensure it's public or ECR permissions are set
```

---

## 📚 Additional Resources

- **Fargate Pricing:** https://aws.amazon.com/fargate/pricing/
- **ECS Best Practices:** https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/
- **Fargate vs EC2 decision tree:** https://aws.amazon.com/blogs/containers/
- **Task sizing guide:** https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html

---

**🎉 Congratulations!** You've deployed a highly-available, auto-scaling, zero-management container application using AWS Fargate!

**Remember:** Delete the stack when done to avoid charges! (~$0.60/hour while running)
