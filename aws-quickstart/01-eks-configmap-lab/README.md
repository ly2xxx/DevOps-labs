# EKS ConfigMap Lab - Configuration Management

**Created:** March 31, 2026  
**Difficulty:** Beginner  
**Time:** 30 minutes  
**Prerequisites:** EKS cluster, kubectl configured

---

## Learning Objectives

By the end of this lab, you will:
- ✅ Create ConfigMaps in EKS
- ✅ Mount ConfigMaps as environment variables
- ✅ Mount ConfigMaps as volume files
- ✅ Edit ConfigMaps using multiple methods
- ✅ Understand ConfigMap update behavior
- ✅ Force pod restarts to pick up changes

---

## Lab Scenario

You're deploying a web application to EKS that needs configuration for:
- Database connection string
- Feature flags
- Application settings

Instead of hardcoding these in the container image, you'll use ConfigMaps for easy updates without rebuilding images.

---

## Lab Architecture

```
┌─────────────────────────────────────────┐
│           EKS Cluster                   │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Namespace: configmap-demo      │  │
│  │                                  │  │
│  │  ┌────────────────────────────┐ │  │
│  │  │   ConfigMap: app-config    │ │  │
│  │  │   - database_url          │ │  │
│  │  │   - feature_flag          │ │  │
│  │  │   - log_level             │ │  │
│  │  └────────────────────────────┘ │  │
│  │              ↓                   │  │
│  │  ┌────────────────────────────┐ │  │
│  │  │   Deployment: demo-app     │ │  │
│  │  │   - Reads ConfigMap        │ │  │
│  │  │   - Displays config values │ │  │
│  │  └────────────────────────────┘ │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## Files in This Lab

| File | Purpose |
|------|---------|
| `00-namespace.yaml` | Create isolated namespace |
| `01-configmap-env.yaml` | ConfigMap as environment variables |
| `02-configmap-volume.yaml` | ConfigMap as mounted files |
| `03-deployment-env.yaml` | App using env var ConfigMap |
| `04-deployment-volume.yaml` | App using volume ConfigMap |
| `05-deployment-both.yaml` | App using both methods |
| `edit-configmap.sh` | Helper script for editing |
| `test-app.yaml` | Simple test application |

---

## Step-by-Step Instructions

### Step 1: Set Up Environment

**Connect to your EKS cluster:**
```bash
# Update kubeconfig (replace with your cluster name)
aws eks update-kubeconfig --name your-cluster-name --region us-east-1

# Verify connection
kubectl cluster-info
kubectl get nodes
```

**Create namespace:**
```bash
kubectl apply -f 00-namespace.yaml
kubectl config set-context --current --namespace=configmap-demo
```

---

### Step 2: Create ConfigMap (Environment Variables Method)

**Apply ConfigMap:**
```bash
kubectl apply -f 01-configmap-env.yaml
```

**Verify:**
```bash
kubectl get configmap app-config
kubectl describe configmap app-config
```

**View content:**
```bash
kubectl get configmap app-config -o yaml
```

---

### Step 3: Deploy Application Using ConfigMap

**Deploy app:**
```bash
kubectl apply -f 03-deployment-env.yaml
```

**Check deployment:**
```bash
kubectl get deployments
kubectl get pods
```

**View logs to see config values:**
```bash
POD_NAME=$(kubectl get pods -l app=demo-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME
```

You should see the app printing the ConfigMap values!

---

### Step 4: Edit ConfigMap - Method 1 (kubectl edit)

**Interactive edit:**
```bash
kubectl edit configmap app-config
```

This opens your default editor (usually `vi` or `nano`).

**Change:**
```yaml
data:
  database_url: "postgres://newdb:5432/myapp"  # Change this
  feature_flag: "true"                         # Change this
  log_level: "debug"                           # Change this
```

Save and exit.

**Verify changes:**
```bash
kubectl get configmap app-config -o yaml
```

**⚠️ Important:** The pod does NOT automatically restart!

---

### Step 5: Restart Pods to Pick Up Changes

**Method 1: Delete pods (let Deployment recreate them)**
```bash
kubectl delete pods -l app=demo-app
```

**Method 2: Rolling restart (recommended)**
```bash
kubectl rollout restart deployment demo-app
```

**Method 3: Scale down and up**
```bash
kubectl scale deployment demo-app --replicas=0
kubectl scale deployment demo-app --replicas=2
```

**Verify new config:**
```bash
sleep 10  # Wait for pods to start
POD_NAME=$(kubectl get pods -l app=demo-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME
```

---

### Step 6: Edit ConfigMap - Method 2 (kubectl apply)

**Edit the YAML file:**
```bash
# Edit 01-configmap-env.yaml with your favorite editor
notepad 01-configmap-env.yaml  # Windows
# OR
nano 01-configmap-env.yaml     # Linux/WSL
```

**Change values:**
```yaml
data:
  database_url: "postgres://proddb:5432/myapp"
  feature_flag: "false"
  log_level: "info"
```

**Apply changes:**
```bash
kubectl apply -f 01-configmap-env.yaml
```

**Restart pods:**
```bash
kubectl rollout restart deployment demo-app
```

---

### Step 7: Edit ConfigMap - Method 3 (kubectl patch)

**Quick single-value update:**
```bash
kubectl patch configmap app-config -p '{"data":{"log_level":"error"}}'
```

**Verify:**
```bash
kubectl get configmap app-config -o jsonpath='{.data.log_level}'
```

**Restart to apply:**
```bash
kubectl rollout restart deployment demo-app
```

---

### Step 8: ConfigMap as Volume (File-Based Config)

**Deploy app with volume-mounted ConfigMap:**
```bash
kubectl apply -f 02-configmap-volume.yaml
kubectl apply -f 04-deployment-volume.yaml
```

**Check the mounted files:**
```bash
POD_NAME=$(kubectl get pods -l app=demo-app-volume -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- ls -la /etc/config
kubectl exec $POD_NAME -- cat /etc/config/database_url
```

**Edit ConfigMap:**
```bash
kubectl edit configmap app-config-volume
```

**⚠️ Important for Volumes:**
Volume-mounted ConfigMaps update **automatically** after ~60 seconds!  
(No pod restart needed, but app must re-read the file)

**Test automatic update:**
```bash
# Edit ConfigMap
kubectl patch configmap app-config-volume -p '{"data":{"log_level":"trace"}}'

# Wait 60 seconds
sleep 60

# Check file content (should be updated!)
kubectl exec $POD_NAME -- cat /etc/config/log_level
```

---

### Step 9: Best Practices

**When to use environment variables vs volumes:**

| Method | Use Case | Update Behavior |
|--------|----------|-----------------|
| **Environment Variables** | Simple config, app reads once at startup | Requires pod restart |
| **Volume Mount** | Config files, app re-reads periodically | Auto-updates (~60s) |

**Recommendation:**
- Use **env vars** for: Database URLs, API keys, simple flags
- Use **volumes** for: Config files (JSON, YAML, XML), large configs, apps that watch files

---

### Step 10: Cleanup

**Delete all resources:**
```bash
kubectl delete namespace configmap-demo
```

**Or delete individually:**
```bash
kubectl delete deployment demo-app demo-app-volume
kubectl delete configmap app-config app-config-volume
kubectl delete namespace configmap-demo
```

---

## Common Commands Cheat Sheet

```bash
# List ConfigMaps
kubectl get configmaps
kubectl get cm  # Shorthand

# Describe ConfigMap
kubectl describe configmap <name>

# View ConfigMap YAML
kubectl get configmap <name> -o yaml

# Edit ConfigMap interactively
kubectl edit configmap <name>

# Create ConfigMap from file
kubectl create configmap <name> --from-file=<file>

# Create ConfigMap from literal values
kubectl create configmap <name> --from-literal=key1=value1 --from-literal=key2=value2

# Patch ConfigMap (single value)
kubectl patch configmap <name> -p '{"data":{"key":"newvalue"}}'

# Delete ConfigMap
kubectl delete configmap <name>

# Force pod restart to pick up ConfigMap changes
kubectl rollout restart deployment <deployment-name>

# Watch pod restart progress
kubectl rollout status deployment <deployment-name>
```

---

## Troubleshooting

### Issue 1: Pods not picking up ConfigMap changes

**Symptoms:** Changed ConfigMap but app still shows old values

**Solution:**
```bash
# Verify ConfigMap was actually updated
kubectl get configmap app-config -o yaml

# Force pod restart
kubectl rollout restart deployment demo-app

# Check pod logs
kubectl logs -l app=demo-app --tail=50
```

---

### Issue 2: ConfigMap not found error

**Symptoms:** Pod shows `CreateContainerConfigError`

**Solution:**
```bash
# Check if ConfigMap exists
kubectl get configmap

# Check pod events
kubectl describe pod <pod-name>

# Verify ConfigMap name matches deployment
kubectl get deployment demo-app -o yaml | grep configMapRef
```

---

### Issue 3: Volume-mounted ConfigMap not updating

**Symptoms:** File content not changing after ConfigMap edit

**Solution:**
```bash
# Check if kubelet has synced (wait 60-90 seconds)
sleep 90

# Verify ConfigMap was updated
kubectl get configmap app-config-volume -o yaml

# Check if app is re-reading the file (app-dependent)
kubectl logs <pod-name>

# If still not working, restart pod
kubectl delete pod <pod-name>
```

---

## Real-World Example: Blue-Green Feature Toggle

**Scenario:** You want to toggle a feature flag without redeploying.

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  new_ui_enabled: "false"
  beta_features: "true"
```

**Enable new UI:**
```bash
kubectl patch configmap feature-flags -p '{"data":{"new_ui_enabled":"true"}}'
kubectl rollout restart deployment frontend-app
```

**Monitor rollout:**
```bash
kubectl rollout status deployment frontend-app
```

**Rollback if needed:**
```bash
kubectl patch configmap feature-flags -p '{"data":{"new_ui_enabled":"false"}}'
kubectl rollout restart deployment frontend-app
```

---

## Advanced: Using ConfigMap with Multiple Containers

**Pod with init container and main container sharing ConfigMap:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  initContainers:
  - name: init
    image: busybox
    command: ['sh', '-c', 'echo $DB_URL']
    envFrom:
    - configMapRef:
        name: app-config
  containers:
  - name: main
    image: nginx
    envFrom:
    - configMapRef:
        name: app-config
```

Both containers see the same ConfigMap values!

---

## Summary

**What you learned:**
- ✅ ConfigMaps store non-sensitive configuration data
- ✅ Two methods: environment variables (requires restart) and volumes (auto-update)
- ✅ Three ways to edit: `kubectl edit`, `kubectl apply`, `kubectl patch`
- ✅ Always restart pods after env var ConfigMap changes
- ✅ Volume-mounted ConfigMaps update automatically (~60s)

**Next Steps:**
- Learn about **Secrets** (for sensitive data like passwords)
- Explore **ConfigMap from files** (`kubectl create configmap --from-file`)
- Study **Helm** (uses ConfigMaps under the hood for values)
- Investigate **External Secrets Operator** (sync from AWS Secrets Manager)

---

## Additional Resources

- **Official Docs:** https://kubernetes.io/docs/concepts/configuration/configmap/
- **AWS EKS Best Practices:** https://aws.github.io/aws-eks-best-practices/
- **ConfigMap vs Secret:** https://kubernetes.io/docs/concepts/configuration/secret/

---

**Lab Complete!** 🎉

You now know how to manage EKS application configuration with ConfigMaps!

**Questions or issues?** Check the troubleshooting section or refer to the Kubernetes docs.

---

**Created:** March 31, 2026  
**Last Updated:** March 31, 2026  
**Tested On:** EKS 1.28+
