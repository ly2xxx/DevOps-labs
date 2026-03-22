# Lab 2: Helm + Nexus Repository

**Learn centralized artifact management with Helm charts**

---

## 📋 What You'll Build

```
┌─────────────┐         ┌─────────────┐         ┌──────────────┐
│  Developer  │────────▶│   Nexus     │────────▶│  OpenShift   │
│             │ Package │ Repository  │ Deploy  │   Cluster    │
└─────────────┘         └─────────────┘         └──────────────┘
      │                                                  │
      │ Create Helm chart                              │
      │ helm package                                   │
      │ Upload to Nexus                                │
      └───────────────────────────────────────────────┘
                    Reproducible deployments
```

---

## 🎯 Learning Objectives

By the end of this lab, you'll be able to:

- [✓] Create a Helm chart for an application
- [✓] Package Helm charts
- [✓] Set up Nexus repository (or use existing)
- [✓] Upload charts to Nexus
- [✓] Deploy from Nexus to OpenShift
- [✓] Manage multiple environments
- [✓] Understand artifact versioning

---

## 📚 Prerequisites

- [ ] OpenShift cluster access (CRC or real cluster)
- [ ] `oc` CLI installed
- [ ] `helm` CLI installed (v3.x)
- [ ] Basic Helm knowledge
- [ ] Docker (optional, for Nexus local setup)

**Check your setup:**
```bash
oc version
helm version
docker version  # Optional
```

---

## 🚀 Lab Steps

### Step 1: Understand the Sample App

We'll deploy a simple **web application** with:
- Node.js web server
- ConfigMap for configuration
- Service and Route
- Multiple environment configurations

**App structure:**
```
sample-app/
├── app/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
└── helm/
    └── webapp/
        ├── Chart.yaml
        ├── values.yaml
        ├── values-dev.yaml
        ├── values-prod.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── route.yaml
            └── configmap.yaml
```

---

### Step 2: Create the Helm Chart

**Navigate to the sample app:**
```bash
cd C:\code\DevOps-labs\openshift-quickstart\02-helm-nexus-lab\sample-app
```

The Helm chart is already created for you. Review the files:

**Chart.yaml:**
```bash
cat helm/webapp/Chart.yaml
```

**values.yaml (default - dev environment):**
```bash
cat helm/webapp/values.yaml
```

**Deployment template:**
```bash
cat helm/webapp/templates/deployment.yaml
```

---

### Step 3: Package the Helm Chart

**Package the chart:**
```bash
cd helm

# Package webapp chart
helm package webapp/

# This creates: webapp-1.0.0.tgz
```

**Verify package:**
```bash
ls -l *.tgz
```

Expected output:
```
webapp-1.0.0.tgz
```

---

### Step 4: Set Up Nexus Repository

#### **Option A: Use Existing Nexus** (Production)

If your organization has Nexus:
```bash
# Configure Helm to use Nexus
helm repo add my-nexus https://nexus.company.com/repository/helm-releases/ \
  --username <your-username> \
  --password <your-password>

# Or use token authentication
helm repo add my-nexus https://nexus.company.com/repository/helm-releases/ \
  --username <username> \
  --password <api-token>
```

#### **Option B: Local Nexus with Docker** (Development)

**Start Nexus locally:**
```bash
# Run Nexus in Docker
docker run -d -p 8081:8081 --name nexus sonatype/nexus3

# Wait for Nexus to start (takes 2-3 minutes)
docker logs -f nexus

# When you see "Started Sonatype Nexus", it's ready
# Access: http://localhost:8081
```

**Initial Nexus setup:**
1. Open browser: `http://localhost:8081`
2. Click "Sign in"
3. Get admin password:
   ```bash
   docker exec nexus cat /nexus-data/admin.password
   ```
4. Login with:
   - Username: `admin`
   - Password: (from above command)
5. Change password when prompted

**Create Helm repository:**
1. Click ⚙️ (Settings) → Repositories
2. Click "Create repository"
3. Select "helm (hosted)"
4. Name: `helm-releases`
5. Click "Create repository"

**Add to Helm:**
```bash
helm repo add my-nexus http://localhost:8081/repository/helm-releases/ \
  --username admin \
  --password <your-new-password>
```

#### **Option C: ChartMuseum** (Lightweight alternative)

```bash
# Run ChartMuseum
docker run -d \
  -p 8080:8080 \
  -e DEBUG=1 \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  -v $(pwd)/charts:/charts \
  ghcr.io/helm/chartmuseum:latest

# Add to Helm
helm repo add chartmuseum http://localhost:8080
```

---

### Step 5: Upload Chart to Nexus

#### **Method 1: Using Nexus UI**

1. Open Nexus: `http://localhost:8081`
2. Browse → helm-releases
3. Click "Upload component"
4. Select `webapp-1.0.0.tgz`
5. Click "Upload"

#### **Method 2: Using cURL**

```bash
# Upload via REST API
curl -u admin:<password> \
  --upload-file webapp-1.0.0.tgz \
  http://localhost:8081/repository/helm-releases/

# Or use Helm plugin (helm-push)
helm plugin install https://github.com/chartmuseum/helm-push
helm cm-push webapp-1.0.0.tgz my-nexus
```

#### **Method 3: Using Nexus Upload Script**

```bash
# Use the provided upload script
./upload-to-nexus.sh webapp-1.0.0.tgz
```

---

### Step 6: Update Helm Repository Index

```bash
# Update local repo cache
helm repo update

# Search for your chart
helm search repo webapp

# Expected output:
# NAME              CHART VERSION   APP VERSION   DESCRIPTION
# my-nexus/webapp   1.0.0           1.0.0         A simple web application
```

---

### Step 7: Deploy from Nexus to OpenShift

**Login to OpenShift:**
```bash
# Using CRC
eval $(crc oc-env)
oc login -u developer -p developer https://api.crc.testing:6443

# Or using real cluster
oc login --token=<your-token> --server=https://api.cluster.com:6443
```

**Create project:**
```bash
oc new-project webapp-dev
```

**Deploy DEV environment:**
```bash
# Install from Nexus
helm install webapp my-nexus/webapp \
  --namespace webapp-dev \
  --values helm/webapp/values-dev.yaml

# Or specify values inline
helm install webapp my-nexus/webapp \
  --namespace webapp-dev \
  --set environment=dev \
  --set replicaCount=1 \
  --set resources.limits.cpu=500m
```

**Verify deployment:**
```bash
# Check Helm release
helm list -n webapp-dev

# Check OpenShift resources
oc get all -n webapp-dev

# Get route
oc get route -n webapp-dev
```

**Access the app:**
```bash
# Get the route URL
APP_URL=$(oc get route webapp -n webapp-dev -o jsonpath='{.spec.host}')
echo "App URL: http://$APP_URL"

# Test
curl http://$APP_URL
```

---

### Step 8: Deploy PROD Environment

**Create prod project:**
```bash
oc new-project webapp-prod
```

**Deploy PROD configuration:**
```bash
# Deploy same chart, different values
helm install webapp my-nexus/webapp \
  --namespace webapp-prod \
  --values helm/webapp/values-prod.yaml

# Or use version pinning
helm install webapp my-nexus/webapp \
  --namespace webapp-prod \
  --version 1.0.0 \
  --values helm/webapp/values-prod.yaml
```

**Verify:**
```bash
helm list -n webapp-prod
oc get all -n webapp-prod
```

---

### Step 9: Update and Upgrade

**Scenario: You fixed a bug, need to release v1.1.0**

**Update Chart.yaml:**
```yaml
# helm/webapp/Chart.yaml
apiVersion: v2
name: webapp
version: 1.1.0  # ← Changed from 1.0.0
appVersion: "1.1.0"
description: A simple web application
```

**Package new version:**
```bash
cd helm
helm package webapp/

# Creates: webapp-1.1.0.tgz
```

**Upload to Nexus:**
```bash
curl -u admin:<password> \
  --upload-file webapp-1.1.0.tgz \
  http://localhost:8081/repository/helm-releases/
```

**Update repo and upgrade:**
```bash
helm repo update

# Upgrade dev
helm upgrade webapp my-nexus/webapp \
  --namespace webapp-dev \
  --version 1.1.0 \
  --values helm/webapp/values-dev.yaml

# Upgrade prod (after testing in dev)
helm upgrade webapp my-nexus/webapp \
  --namespace webapp-prod \
  --version 1.1.0 \
  --values helm/webapp/values-prod.yaml
```

---

### Step 10: Rollback (if something breaks)

```bash
# Check release history
helm history webapp -n webapp-prod

# Rollback to previous version
helm rollback webapp -n webapp-prod

# Or rollback to specific revision
helm rollback webapp 1 -n webapp-prod
```

---

## 🔍 Verification Checklist

After completing the lab, verify:

- [ ] Chart is packaged (`.tgz` file exists)
- [ ] Chart is uploaded to Nexus
- [ ] `helm search repo webapp` finds the chart
- [ ] Dev environment deployed successfully
- [ ] Prod environment deployed with different config
- [ ] Can access app via OpenShift route
- [ ] Can upgrade to new version
- [ ] Can rollback if needed

---

## 📊 Lab Architecture

**What you've built:**

```
┌──────────────────────────────────────────────────┐
│              Nexus Repository                     │
│                                                   │
│  helm-releases/                                   │
│  ├── webapp-1.0.0.tgz                            │
│  ├── webapp-1.1.0.tgz                            │
│  └── index.yaml                                  │
└──────────────────────────────────────────────────┘
                      │
         ┌────────────┼────────────┐
         │                         │
         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐
│   DEV Project   │       │  PROD Project   │
│                 │       │                 │
│  webapp v1.1.0  │       │  webapp v1.1.0  │
│  - 1 replica    │       │  - 3 replicas   │
│  - 500m CPU     │       │  - 2000m CPU    │
│  - Dev config   │       │  - Prod config  │
└─────────────────┘       └─────────────────┘
```

---

## 💡 Key Takeaways

### **Pros of Helm + Nexus:**
✅ **Centralized artifact storage** - Single source for all charts  
✅ **Version control** - Immutable artifacts with clear versions  
✅ **Security scanning** - Scan charts before deployment  
✅ **Reproducibility** - Same artifact, guaranteed  
✅ **Offline capability** - Download once, deploy many times  

### **Cons:**
❌ **Manual process** - Developers must package, upload, deploy  
❌ **No automatic sync** - Changes require manual intervention  
❌ **No drift detection** - Manual changes aren't corrected  

---

## 🚀 Next Steps

1. **Try Lab 3** - See how ArgoCD automates this entire workflow
2. **Compare** - Notice the difference in deployment speed and automation
3. **Combine** - Consider using Nexus for artifact storage + ArgoCD for GitOps

---

## 🔧 Troubleshooting

### **Issue: Nexus not accessible**
```bash
# Check Nexus status
docker ps | grep nexus
docker logs nexus

# Restart Nexus
docker restart nexus
```

### **Issue: helm repo add fails**
```bash
# Check Nexus is running
curl http://localhost:8081

# Verify repository exists in Nexus UI

# Try with --insecure-skip-tls-verify if using self-signed certs
helm repo add my-nexus https://nexus.local/repository/helm-releases/ \
  --insecure-skip-tls-verify
```

### **Issue: Chart not found after upload**
```bash
# Rebuild Nexus index
# In Nexus UI: Browse → helm-releases → Rebuild index

# Update Helm repo cache
helm repo update

# Force refresh
helm repo remove my-nexus
helm repo add my-nexus <url>
```

---

## 📚 Additional Resources

- [Helm Docs](https://helm.sh/docs/)
- [Nexus Repository Manager](https://help.sonatype.com/repomanager3)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)

---

Ready to see how ArgoCD automates this? → [Lab 3: Helm + ArgoCD](../03-helm-argocd-lab/README.md)
