# Quick Start - Helm Secrets Rotation Lab

**Goal:** Learn Helm deployments and secret rotation strategies in 30 minutes.

---

## Prerequisites

```powershell
# 1. CRC running
crc start

# 2. Logged in as developer
oc login -u developer https://api.crc.testing:6443

# 3. Helm installed
helm version
```

---

## Fast Track (Copy-Paste)

### Step 1: Setup Chart (5 minutes)

```powershell
cd C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation

# Run setup script
.\setup-lab.ps1

# Navigate to chart
cd my-app-chart\my-app
```

### Step 2: Deploy Application (2 minutes)

```powershell
# Create namespace
oc new-project helm-secrets-lab

# Install chart
helm install my-app . -n helm-secrets-lab

# Verify deployment
helm list -n helm-secrets-lab
oc get pods -n helm-secrets-lab
```

### Step 3: Verify Secrets (3 minutes)

```powershell
# Get pod name
$POD = oc get pod -n helm-secrets-lab -l app.kubernetes.io/name=my-app -o jsonpath='{.items[0].metadata.name}'

# Check environment variables
oc exec -n helm-secrets-lab $POD -- env | Select-String DATABASE

# Check mounted secrets (as files)
oc exec -n helm-secrets-lab $POD -- cat /etc/secrets/databasePassword
oc exec -n helm-secrets-lab $POD -- cat /etc/config/app-config.json
```

### Step 4: Rotate Secret (5 minutes)

```powershell
# Edit values.yaml - change secret value
# File: my-app-chart\my-app\values.yaml
# Line: databasePassword: "initial_password_123"
# Change to: databasePassword: "rotated_password_456"

# Upgrade release (triggers rolling update)
helm upgrade my-app . -n helm-secrets-lab

# Watch rolling update
oc get pods -n helm-secrets-lab -w

# Verify new secret after rollout completes
$POD = oc get pod -n helm-secrets-lab -l app.kubernetes.io/name=my-app -o jsonpath='{.items[0].metadata.name}'
oc exec -n helm-secrets-lab $POD -- cat /etc/secrets/databasePassword
```

**Result:** Should show "rotated_password_456"

### Step 5: Test Rollback (5 minutes)

```powershell
# List all revisions
helm history my-app -n helm-secrets-lab

# Rollback to revision 1 (original password)
helm rollback my-app 1 -n helm-secrets-lab

# Verify rollback
$POD = oc get pod -n helm-secrets-lab -l app.kubernetes.io/name=my-app -o jsonpath='{.items[0].metadata.name}'
oc exec -n helm-secrets-lab $POD -- cat /etc/secrets/databasePassword
```

**Result:** Should show "initial_password_123" again

---

## What You Just Learned

✅ Created a Helm chart from scratch  
✅ Deployed to OKD with Helm  
✅ Managed secrets via Helm values  
✅ Triggered zero-downtime rolling update on secret change  
✅ Performed Helm rollback  

**Key Insight:** The `checksum/secret` annotation automatically triggers pod restarts when secrets change!

---

## Next Steps

1. **Read the full guide:** `README.md`
2. **Try other rotation strategies:**
   - Hot-reload with volume mounts
   - Blue-green deployments
   - Versioned secrets
3. **Explore Helm features:**
   - Separate values files per environment
   - Helm hooks
   - Chart dependencies

---

## Cleanup

```powershell
# Uninstall release
helm uninstall my-app -n helm-secrets-lab

# Delete namespace
oc delete project helm-secrets-lab

# Optional: Remove chart
cd C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation
.\setup-lab.ps1 -CleanupOnly
```

---

## Troubleshooting

### Chart Not Found
```powershell
# Make sure you're in the chart directory
cd C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation\my-app-chart\my-app
helm install my-app . -n helm-secrets-lab
```

### Pods Not Starting
```powershell
# Check pod events
oc describe pod -l app.kubernetes.io/name=my-app -n helm-secrets-lab

# Check logs
oc logs -l app.kubernetes.io/name=my-app -n helm-secrets-lab
```

### Secret Not Updating
```powershell
# Ensure checksum annotation exists in deployment template
helm get manifest my-app -n helm-secrets-lab | Select-String checksum

# Force new rollout
oc rollout restart deployment/my-app-my-app -n helm-secrets-lab
```

---

## Cheat Sheet

```powershell
# Helm commands
helm install <release> <chart> -n <namespace>
helm upgrade <release> <chart> -n <namespace>
helm list -n <namespace>
helm history <release> -n <namespace>
helm rollback <release> <revision> -n <namespace>
helm uninstall <release> -n <namespace>

# OKD commands
oc get pods -n <namespace>
oc get all -n <namespace>
oc logs <pod-name> -n <namespace>
oc exec <pod-name> -n <namespace> -- <command>
oc rollout status deployment/<name> -n <namespace>

# Debugging
helm template <chart> > rendered.yaml
helm lint <chart>
helm get values <release> -n <namespace>
helm get manifest <release> -n <namespace>
```

---

**Time to complete:** ~30 minutes  
**Difficulty:** Beginner-Intermediate  
**Lab date:** March 2026

Happy learning! 🚀
