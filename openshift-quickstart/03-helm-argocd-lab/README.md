# Lab 3: Helm + ArgoCD (GitOps)

**Learn automated GitOps deployments with ArgoCD**

---

## 📋 What You'll Build

```
┌──────────┐        ┌───────────┐        ┌──────────────┐
│   Git    │───────▶│  ArgoCD   │───────▶│  OpenShift   │
│ (Source) │ Watch  │(Operator) │ Sync   │   Cluster    │
└──────────┘        └───────────┘        └──────────────┘
     │                     │                      │
     │ Developer commits   │ Detects changes     │ Auto-deploys
     │ Helm chart          │ Pulls from Git      │ Self-heals
     └─────────────────────┴─────────────────────┘
              GitOps: Git is the single source of truth
```

---

## 🎯 Learning Objectives

By the end of this lab, you'll be able to:

- [✓] Install ArgoCD on OpenShift
- [✓] Create ArgoCD applications
- [✓] Configure automatic sync from Git
- [✓] Deploy multi-environment apps
- [✓] Enable drift detection and self-healing
- [✓] Perform GitOps-based rollbacks
- [✓] Understand continuous delivery patterns

---

## 📚 Prerequisites

- [ ] OpenShift cluster access (CRC or real cluster)
- [ ] `oc` CLI installed
- [ ] `helm` CLI installed
- [ ] Git repository access (GitHub, GitLab, or Bitbucket)
- [ ] Completion of Lab 2 (recommended for comparison)

---

## 🚀 Lab Steps

### Step 1: Understand GitOps Principles

**GitOps Core Concepts:**

1. **Git as Single Source of Truth**
   - All config in Git
   - No manual `kubectl`/`oc` commands
   - Changes via pull requests

2. **Declarative Configuration**
   - Desired state in YAML
   - System converges to desired state
   - Kubernetes-native

3. **Automatic Sync**
   - ArgoCD watches Git repo
   - Automatically deploys changes
   - No human intervention needed

4. **Self-Healing**
   - Detects manual changes
   - Reverts to Git state
   - Ensures consistency

---

### Step 2: Install ArgoCD on OpenShift

**Option A: Using Operator (Recommended for OpenShift)**

```bash
# Login as admin (or user with cluster-admin)
oc login -u kubeadmin

# Create ArgoCD namespace
oc new-project argocd

# Install ArgoCD Operator
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: argocd-operator
  namespace: argocd
spec:
  channel: alpha
  name: argocd-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF

# Wait for operator to be ready (takes 1-2 minutes)
oc get csv -n argocd -w
# Wait until STATUS shows "Succeeded"

# Create ArgoCD instance
cat <<EOF | oc apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: argocd
  namespace: argocd
spec:
  server:
    route:
      enabled: true
EOF
```

**Option B: Using Manifest (Alternative)**

```bash
# Create namespace
oc new-project argocd

# Install ArgoCD
oc apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose ArgoCD server via route
oc expose svc argocd-server -n argocd
```

**Verify installation:**

```bash
# Check pods
oc get pods -n argocd

# Expected: All pods Running
# argocd-server-xxx
# argocd-repo-server-xxx
# argocd-application-controller-xxx
# argocd-redis-xxx
```

---

### Step 3: Access ArgoCD UI

**Get the route:**

```bash
# Get ArgoCD route URL
ARGOCD_URL=$(oc get route argocd-server -n argocd -o jsonpath='{.spec.host}')
echo "ArgoCD URL: https://$ARGOCD_URL"
```

**Get initial admin password:**

```bash
# Get password
ARGOCD_PASSWORD=$(oc get secret argocd-cluster -n argocd -o jsonpath='{.data.admin\.password}' | base64 -d)
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
```

**Login to UI:**

1. Open browser: `https://<ARGOCD_URL>`
2. Accept self-signed certificate warning
3. Login with:
   - Username: `admin`
   - Password: (from above)

**Optional: Install ArgoCD CLI**

```bash
# Download ArgoCD CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

# Make executable
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Login via CLI
argocd login $ARGOCD_URL --username admin --password $ARGOCD_PASSWORD --insecure
```

---

### Step 4: Prepare Git Repository

**You need a Git repository with your Helm charts.**

**Option A: Use This Lab's Sample App**

```bash
# Initialize Git in sample-app folder
cd C:\code\DevOps-labs\openshift-quickstart\03-helm-argocd-lab\sample-app

git init
git add .
git commit -m "Initial commit: Helm chart for GitOps"

# Push to your Git provider (GitHub/GitLab)
# Example for GitHub:
git remote add origin https://github.com/YOUR_USERNAME/argocd-demo-app.git
git push -u origin main
```

**Option B: Fork Example Repository**

```bash
# Fork this example repo:
# https://github.com/argoproj/argocd-example-apps

# Clone your fork
git clone https://github.com/YOUR_USERNAME/argocd-example-apps.git
```

**For this lab, we'll use Option A (local sample app).**

---

### Step 5: Create ArgoCD Application (Dev Environment)

**Method 1: Using ArgoCD UI**

1. Open ArgoCD UI
2. Click "NEW APP"
3. Fill in:
   - **Application Name:** `webapp-dev`
   - **Project:** `default`
   - **Sync Policy:** `Manual` (we'll enable auto later)
   - **Repository URL:** `https://github.com/YOUR_USERNAME/argocd-demo-app.git`
   - **Revision:** `HEAD` or `main`
   - **Path:** `helm/webapp`
   - **Cluster:** `https://kubernetes.default.svc` (in-cluster)
   - **Namespace:** `webapp-dev`
   - **Helm Values:** Select `values-dev.yaml`
4. Click "CREATE"

**Method 2: Using YAML Manifest**

```bash
cat <<EOF | oc apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webapp-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-demo-app.git
    targetRevision: HEAD
    path: helm/webapp
    helm:
      valueFiles:
        - values-dev.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: webapp-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

**Method 3: Using ArgoCD CLI**

```bash
argocd app create webapp-dev \
  --repo https://github.com/YOUR_USERNAME/argocd-demo-app.git \
  --path helm/webapp \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace webapp-dev \
  --values values-dev.yaml \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

---

### Step 6: Sync and Deploy

**Using UI:**
1. Click on `webapp-dev` app
2. Click "SYNC"
3. Click "SYNCHRONIZE"
4. Watch deployment in real-time!

**Using CLI:**

```bash
# Manual sync
argocd app sync webapp-dev

# Watch sync status
argocd app get webapp-dev --watch
```

**Verify deployment:**

```bash
# Check in OpenShift
oc get all -n webapp-dev

# Get app route
oc get route -n webapp-dev
```

**Test the app:**

```bash
APP_URL=$(oc get route webapp -n webapp-dev -o jsonpath='{.spec.host}')
curl http://$APP_URL
```

---

### Step 7: Enable Automatic Sync

**In ArgoCD UI:**
1. Click `webapp-dev` app
2. Click "APP DETAILS"
3. Click "ENABLE AUTO-SYNC"
4. Enable "PRUNE RESOURCES" (delete resources removed from Git)
5. Enable "SELF HEAL" (revert manual changes)

**Using CLI:**

```bash
argocd app set webapp-dev --sync-policy automated --auto-prune --self-heal
```

**What this does:**
- ✅ ArgoCD checks Git every 3 minutes
- ✅ Automatically deploys changes
- ✅ Deletes resources removed from Git
- ✅ Reverts manual changes back to Git state

---

### Step 8: Test GitOps Workflow (Make a Change)

**Scenario: Update app version to 1.1.0**

**1. Update Chart.yaml:**

```bash
cd sample-app/helm/webapp

# Edit Chart.yaml
cat > Chart.yaml <<EOF
apiVersion: v2
name: webapp
description: A simple web application
version: 1.1.0
appVersion: "1.1.0"
EOF
```

**2. Commit and push:**

```bash
git add Chart.yaml
git commit -m "Bump version to 1.1.0"
git push
```

**3. Watch ArgoCD auto-deploy:**

```bash
# Watch in CLI
argocd app wait webapp-dev

# Or watch in UI (refresh page)
# ArgoCD will detect change within 3 minutes and auto-deploy
```

**Verify update:**

```bash
# Check deployment
oc get deployment webapp -n webapp-dev -o yaml | grep appVersion

# Should show: "1.1.0"
```

---

### Step 9: Test Self-Healing (Manual Change Revert)

**Scenario: Someone manually scales the deployment**

```bash
# Manually scale deployment
oc scale deployment webapp --replicas=5 -n webapp-dev

# Check replicas
oc get deployment webapp -n webapp-dev
# Should show: READY 5/5

# Wait ~30 seconds for ArgoCD to detect drift
# ArgoCD will auto-revert back to replicas=1 (from Git)

# Check again
oc get deployment webapp -n webapp-dev
# Should show: READY 1/1 (reverted!)
```

**In ArgoCD UI:**
- You'll see the app status change to "OutOfSync"
- Then auto-sync back to "Synced"
- Self-healing in action! 🎯

---

### Step 10: Deploy Production Environment

**Create prod application:**

```bash
cat <<EOF | oc apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webapp-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-demo-app.git
    targetRevision: HEAD
    path: helm/webapp
    helm:
      valueFiles:
        - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: webapp-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

**Or using CLI:**

```bash
argocd app create webapp-prod \
  --repo https://github.com/YOUR_USERNAME/argocd-demo-app.git \
  --path helm/webapp \
  --dest-namespace webapp-prod \
  --values values-prod.yaml \
  --sync-policy automated
```

**Sync prod:**

```bash
argocd app sync webapp-prod
argocd app wait webapp-prod
```

---

### Step 11: GitOps Rollback (Git Revert)

**Scenario: Version 1.1.0 has a bug, rollback to 1.0.0**

**Using Git revert:**

```bash
cd sample-app

# Find the commit to revert
git log --oneline

# Revert the version bump commit
git revert <commit-hash>

# Push revert
git push
```

**ArgoCD will automatically:**
1. Detect the revert
2. Sync back to version 1.0.0
3. Deploy the rollback
4. Show status in UI

**Verify:**

```bash
# Check version
oc get deployment webapp -n webapp-dev -o yaml | grep appVersion
# Should show: "1.0.0" (rolled back!)
```

---

## 🔍 Verification Checklist

After completing the lab, verify:

- [ ] ArgoCD installed and accessible
- [ ] ArgoCD UI accessible
- [ ] Git repository connected
- [ ] Dev environment auto-deploys from Git
- [ ] Prod environment deployed with different config
- [ ] App accessible via OpenShift route
- [ ] Git push triggers auto-deployment
- [ ] Manual changes are auto-reverted (self-healing)
- [ ] Git revert performs rollback

---

## 📊 Lab Architecture

**What you've built:**

```
┌────────────────────────────────────────────┐
│           Git Repository                    │
│                                             │
│  helm/webapp/                               │
│  ├── Chart.yaml (v1.1.0)                   │
│  ├── values-dev.yaml                       │
│  ├── values-prod.yaml                      │
│  └── templates/                            │
└────────────────────────────────────────────┘
                │
                │ ArgoCD watches (every 3 min)
                ▼
┌────────────────────────────────────────────┐
│            ArgoCD                           │
│                                             │
│  Applications:                              │
│  ├── webapp-dev (auto-sync, self-heal)     │
│  └── webapp-prod (auto-sync)               │
└────────────────────────────────────────────┘
                │
       ┌────────┴────────┐
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│  DEV Project│   │ PROD Project│
│  webapp-dev │   │ webapp-prod │
│  - 1 replica│   │ - 3 replicas│
│  - Auto-sync│   │ - Auto-sync │
│  - Self-heal│   │ - Self-heal │
└─────────────┘   └─────────────┘
```

---

## 💡 Key Takeaways

### **Pros of Helm + ArgoCD (GitOps):**
✅ **Full automation** - Push to Git, deploy automatically  
✅ **Git as source of truth** - Audit trail in Git history  
✅ **Drift detection** - Catches manual changes  
✅ **Self-healing** - Auto-corrects configuration  
✅ **Easy rollback** - Git revert = instant rollback  
✅ **Multi-cluster support** - Manage many clusters from one ArgoCD  
✅ **Declarative** - Desired state in Git  

### **Cons:**
❌ **More complex setup** - Need ArgoCD infrastructure  
❌ **Learning curve** - New concepts (GitOps, CRDs)  
❌ **Git dependency** - Git must be available  

---

## 🔄 Comparison: Lab 2 vs Lab 3

| Task | Lab 2 (Helm + Nexus) | Lab 3 (Helm + ArgoCD) |
|------|---------------------|----------------------|
| **Deploy new version** | Package → Upload → `helm upgrade` | Git commit → Push (done!) |
| **Rollback** | `helm rollback` | Git revert → Push |
| **Multi-environment** | Manual `helm install` per env | One ArgoCD app per env, auto-sync |
| **Drift fix** | Manual detection + fix | Automatic detection + revert |
| **Audit trail** | Artifact versions in Nexus | Git commit history |
| **Deployment time** | Manual (minutes) | Automatic (seconds after push) |
| **Human intervention** | Required for every deploy | None (after initial setup) |

---

## 🚀 Advanced Topics (Optional)

### **1. App of Apps Pattern**

Manage multiple apps with one parent app:

```yaml
# argocd-apps/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-apps
    targetRevision: HEAD
    path: argocd-apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated: {}
```

### **2. Sync Waves (Ordered Deployment)**

Deploy resources in order using annotations:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy first
```

### **3. Health Checks**

Custom health checks for CRDs:

```yaml
resource.customizations.health:
  MyCustomResource: |
    hs = {}
    if obj.status.ready == true then
      hs.status = "Healthy"
    else
      hs.status = "Progressing"
    end
    return hs
```

### **4. Notification Webhooks**

Get Slack/Teams notifications:

```bash
argocd app set webapp-dev \
  --notification-webhook https://hooks.slack.com/services/YOUR/WEBHOOK
```

---

## 🔧 Troubleshooting

### **Issue: ArgoCD can't reach Git repo**

```bash
# Test Git access from ArgoCD
oc exec -n argocd argocd-repo-server-xxx -- git ls-remote https://github.com/YOUR_USERNAME/repo.git

# If private repo, add credentials:
argocd repo add https://github.com/YOUR_USERNAME/repo.git \
  --username <username> \
  --password <token>
```

### **Issue: App stuck in "Progressing"**

```bash
# Check app status
argocd app get webapp-dev

# Check sync status
argocd app logs webapp-dev

# Force refresh
argocd app get webapp-dev --refresh
```

### **Issue: Self-healing not working**

```bash
# Check if self-heal is enabled
argocd app get webapp-dev -o yaml | grep selfHeal

# If missing, enable:
argocd app set webapp-dev --self-heal
```

---

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

---

**🎉 Congratulations!** You've mastered GitOps with Helm + ArgoCD!

**Compare:** How much faster/easier was this than Lab 2? That's the power of GitOps! 🚀
