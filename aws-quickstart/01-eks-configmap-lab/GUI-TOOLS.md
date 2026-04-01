# GUI Tools for Editing ConfigMaps

**Alternative to kubectl command line**

Instead of `kubectl edit`, you can use visual tools to edit ConfigMaps with a nice GUI.

---

## Option 1: Lens (Recommended) ⭐

**Best choice for beginners and visual learners**

### What is Lens?

Lens is a free desktop application that gives you a beautiful visual interface for Kubernetes clusters. Think of it as "the Kubernetes IDE."

**Website:** https://k8slens.dev/

### Features:
- ✅ Visual ConfigMap editor (no YAML knowledge needed)
- ✅ Real-time cluster monitoring
- ✅ Built-in terminal
- ✅ Works on Windows, Mac, Linux
- ✅ Auto-discovers EKS clusters from kubeconfig
- ✅ Free for personal use

---

### Setup Guide (10 minutes)

**Step 1: Download Lens**
1. Go to https://k8slens.dev/
2. Click "Download" (Windows version)
3. Run the installer
4. Launch Lens

**Step 2: Connect to Your EKS Cluster**

Lens auto-detects clusters from your kubeconfig file.

```bash
# First, ensure your EKS cluster is in kubeconfig
aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region YOUR_REGION
```

Then in Lens:
1. Open Lens
2. Click "Catalog" (left sidebar)
3. Your EKS cluster should appear automatically
4. Click "Connect"

If not auto-detected:
1. Click "+" (Add Cluster)
2. Paste your kubeconfig content
3. Click "Add Cluster"

**Step 3: Navigate to ConfigMaps**

1. In Lens, select your cluster
2. Left sidebar: Click "Config" → "ConfigMaps"
3. You'll see all ConfigMaps in all namespaces

**Step 4: Edit a ConfigMap**

**Visual Method:**
1. Find your ConfigMap (e.g., `app-config` in `configmap-demo` namespace)
2. Click on it
3. Click "Edit" (top right)
4. Edit values in the built-in YAML editor
5. Click "Save"

**Done!** No kubectl needed.

**Step 5: Restart Deployment (if needed)**

In Lens:
1. Go to "Workloads" → "Deployments"
2. Find your deployment (e.g., `demo-app`)
3. Click the three dots (⋮)
4. Select "Restart"

---

### Lens Screenshot Guide

**Finding ConfigMaps:**
```
Lens Dashboard
├── Cluster: your-eks-cluster
│   ├── Workloads
│   ├── Config
│   │   ├── ConfigMaps ← Click here
│   │   ├── Secrets
│   │   └── ...
```

**Editing ConfigMap:**
```
ConfigMap: app-config
┌─────────────────────────────────────┐
│ Edit (button)                       │
│                                     │
│ apiVersion: v1                      │
│ kind: ConfigMap                     │
│ metadata:                           │
│   name: app-config                  │
│ data:                               │
│   database_url: "postgres://..."   │ ← Edit this
│   log_level: "info"                 │ ← Edit this
│                                     │
│ [Cancel]  [Save]                    │
└─────────────────────────────────────┘
```

---

### Lens Tips:

**Tip 1: Multi-Cluster Management**
- Add multiple EKS clusters
- Switch between them easily
- See all clusters in one place

**Tip 2: Built-in Terminal**
- Click terminal icon (bottom)
- Run kubectl commands directly in Lens
- Auto-authenticated to current cluster

**Tip 3: Resource Monitoring**
- Real-time CPU/memory graphs
- Pod logs viewer
- Event stream

**Tip 4: Search Everything**
- Press `Ctrl+P` (Windows) / `Cmd+P` (Mac)
- Search for any resource by name
- Jump to ConfigMaps instantly

---

## Option 2: Kubernetes Dashboard

**Official Kubernetes web UI**

### What is Kubernetes Dashboard?

A web-based UI for Kubernetes clusters. Runs inside your cluster as a deployment.

**Official Docs:** https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

### Features:
- ✅ Web-based (no installation)
- ✅ Edit ConfigMaps visually
- ✅ View cluster resources
- ✅ Deploy applications
- ❌ Requires port-forwarding
- ❌ Security setup needed

---

### Setup Guide (20 minutes)

**Step 1: Deploy Dashboard to EKS**

```bash
# Install Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Verify deployment
kubectl get pods -n kubernetes-dashboard
```

Wait for pod to be `Running`.

**Step 2: Create Admin User**

Create a service account with admin permissions:

```bash
# Create file: dashboard-admin.yaml
cat > dashboard-admin.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Apply
kubectl apply -f dashboard-admin.yaml
```

**Step 3: Get Access Token**

```bash
# Get token (you'll need this to login)
kubectl -n kubernetes-dashboard create token admin-user
```

**Copy the token!** You'll use it to login.

**Step 4: Start Proxy**

```bash
kubectl proxy
```

Keep this terminal running.

**Step 5: Access Dashboard**

Open your browser to:
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**Step 6: Login**

1. Select "Token" authentication
2. Paste the token from Step 3
3. Click "Sign In"

**Step 7: Edit ConfigMap**

1. Select namespace: `configmap-demo`
2. Click "Config and Storage" → "Config Maps"
3. Click on `app-config`
4. Click "Edit" (top right, pencil icon)
5. Modify values
6. Click "Update"

**Step 8: Restart Deployment**

1. Go to "Workloads" → "Deployments"
2. Find `demo-app`
3. Click three dots (⋮)
4. Select "Restart"

---

### Dashboard Tips:

**Tip 1: Bookmarking**
Save the URL with token:
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
```

**Tip 2: Token Expiry**
Tokens expire. To get a new one:
```bash
kubectl -n kubernetes-dashboard create token admin-user
```

**Tip 3: Stopping Proxy**
Press `Ctrl+C` in the terminal running `kubectl proxy`

**Tip 4: Security**
⚠️ **Don't expose dashboard publicly!** Always use `kubectl proxy` or port-forwarding.

---

### Dashboard vs Lens:

| Feature | Lens | Dashboard |
|---------|------|-----------|
| **Installation** | Desktop app | Deploy to cluster |
| **Access** | Direct | Via kubectl proxy |
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Security Setup** | None | Required |
| **Multi-Cluster** | Easy | One at a time |
| **Offline Use** | ✅ Yes | ❌ No (needs cluster) |

**Verdict:** Lens is easier for beginners!

---

## Option 3: VS Code Kubernetes Extension

**If you already use VS Code**

### What is it?

A VS Code extension that adds Kubernetes support to your editor.

**Extension:** `ms-kubernetes-tools.vscode-kubernetes-tools`

### Features:
- ✅ Integrated with VS Code
- ✅ Right-click to edit ConfigMaps
- ✅ Apply YAML directly
- ✅ Terminal built-in

---

### Setup Guide (5 minutes)

**Step 1: Install Extension**

1. Open VS Code
2. Press `Ctrl+Shift+X` (Extensions)
3. Search: "Kubernetes"
4. Install "Kubernetes" by Microsoft
5. Reload VS Code

**Step 2: Connect to Cluster**

The extension auto-detects clusters from kubeconfig.

1. Click Kubernetes icon (left sidebar)
2. Expand "Clusters"
3. Right-click your EKS cluster → "Set as Current Cluster"

**Step 3: Edit ConfigMap**

1. Expand "Clusters" → Your cluster → "Namespaces" → `configmap-demo`
2. Expand "Config Maps"
3. Right-click `app-config` → "Get"
4. Edit the YAML in VS Code editor
5. Right-click the file → "Kubernetes: Apply"

**Done!**

---

### VS Code Tips:

**Tip 1: Create Resources**
- Right-click namespace → "Create"
- Paste YAML
- Apply

**Tip 2: View Logs**
- Right-click pod → "Logs"
- Tail logs in VS Code terminal

**Tip 3: Port Forwarding**
- Right-click service → "Port Forward"
- Access app on localhost

**Tip 4: Terminal**
- Right-click pod → "Terminal"
- Exec into pod directly

---

## Option 4: Cloud9 (AWS Cloud IDE)

**If you want an AWS-native solution**

### What is Cloud9?

AWS's cloud-based IDE with kubectl pre-installed.

**AWS Docs:** https://aws.amazon.com/cloud9/

### Features:
- ✅ Web-based
- ✅ kubectl pre-installed
- ✅ AWS IAM integrated
- ❌ Still uses kubectl commands (no visual editor)
- 💰 Small hourly cost (free tier available)

---

### Setup Guide (15 minutes)

**Step 1: Create Cloud9 Environment**

1. Go to AWS Console → Cloud9
2. Click "Create environment"
3. Name: "eks-admin"
4. Instance type: t3.small (or t2.micro for free tier)
5. Click "Create"

Wait 2-3 minutes for environment to start.

**Step 2: Install kubectl**

Cloud9 may have kubectl, but ensure it's the right version:

```bash
# Check version
kubectl version --client

# If needed, install/update
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Step 3: Configure AWS CLI**

```bash
# Cloud9 inherits IAM role automatically
aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region YOUR_REGION
```

**Step 4: Edit ConfigMap**

```bash
# Same kubectl commands as before
kubectl edit configmap app-config -n configmap-demo
```

Cloud9 opens `vi` editor in the terminal.

**Not really a GUI, but convenient if you're already in AWS Console!**

---

## Comparison Table

| Tool | Type | Ease | Cost | Offline | Visual Editor |
|------|------|------|------|---------|---------------|
| **Lens** | Desktop | ⭐⭐⭐⭐⭐ | Free | ✅ Yes | ✅ Yes |
| **Dashboard** | Web (in-cluster) | ⭐⭐⭐ | Free | ❌ No | ✅ Yes |
| **VS Code** | IDE Extension | ⭐⭐⭐⭐ | Free | ✅ Yes | ⚠️ YAML only |
| **Cloud9** | Web IDE | ⭐⭐⭐ | 💰 Paid | ❌ No | ❌ kubectl only |
| **kubectl CLI** | Command line | ⭐⭐ | Free | ✅ Yes | ❌ No |

---

## Recommended Setup

**For Weekend Experimentation:**

1. **Start with Lens** (easiest, most visual)
   - 10 min setup
   - Beautiful UI
   - No port-forwarding needed

2. **Try Kubernetes Dashboard** (optional)
   - Official tool
   - Good to know for production

3. **Skip Cloud9** (unless you love AWS Console)
   - Not worth the cost for just editing ConfigMaps

4. **Add VS Code extension** (if you use VS Code daily)
   - Nice integration
   - Good for dev workflows

---

## Weekend Lab Plan

**Saturday Morning (1 hour):**

1. Install Lens
2. Connect to your EKS cluster
3. Deploy the ConfigMap lab resources (from last night)
4. Edit ConfigMaps in Lens
5. Restart deployments in Lens
6. Compare with kubectl experience

**Saturday Afternoon (Optional, 30 mins):**

1. Deploy Kubernetes Dashboard
2. Create admin token
3. Login to Dashboard
4. Edit same ConfigMap
5. Compare Lens vs Dashboard experience

**Verdict by Saturday evening:**
You'll know which tool you prefer! (Spoiler: probably Lens)

---

## Troubleshooting

### Lens won't connect to EKS?

**Check kubeconfig:**
```bash
kubectl config view
kubectl get nodes  # Should work
```

If kubectl works, Lens should auto-detect the cluster.

**Manual add:**
1. In Lens: File → Add Cluster
2. Paste kubeconfig content
3. Click Add

### Dashboard token expired?

```bash
# Get new token
kubectl -n kubernetes-dashboard create token admin-user
```

### VS Code extension not showing cluster?

1. Press `F1` in VS Code
2. Type "Kubernetes: Refresh"
3. Press Enter

---

## Summary

**TL;DR for Master Yang:**

This weekend:
1. **Download Lens** from https://k8slens.dev/
2. Install (5 mins)
3. Connect to your EKS cluster (auto-detects)
4. Edit ConfigMaps visually (no kubectl needed!)

**That's it!** Way easier than `kubectl edit` for beginners.

---

**Next Steps:**
- Try Lens first (recommended)
- Then experiment with Dashboard if curious
- Stick with what feels most comfortable

**Have fun exploring this weekend!** 🚀

---

**Created:** April 1, 2026  
**Last Updated:** April 1, 2026  
**For Lab:** `C:\code\DevOps-labs\aws-quickstart\01-eks-configmap-lab\`
