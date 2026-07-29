# Helm Hands-On Cheat Sheet

A complete guide to packaging, configuring, and managing our Nginx Webserver application using Helm.

---

## 📁 1. Helm Chart Directory Structure

```text
helm/
├── Chart.yaml             # Chart metadata (name, version, appVersion)
├── values.yaml            # Configurable parameters & default values
├── cheatsheet.md          # Helm commands & walkthrough guide
└── templates/             # Kubernetes template manifests
    ├── _helpers.tpl       # Named template helper functions
    ├── configmap.yaml     # ConfigMap template (HTML & Key/Values)
    ├── secret.yaml        # Secret template (Base64 credentials)
    ├── deployment.yaml    # Deployment template with probes & mounts
    ├── service.yaml       # Service template (NodePort / ClusterIP)
    ├── ingress.yaml       # Ingress routing template
    └── curlpod.yaml       # In-cluster testing pod template
```

---

## 🚀 2. Essential Helm Commands Reference

### 1. Template Rendering & Dry-Run (Validation)
Test template rendering locally without contacting the Kubernetes cluster:
```powershell
# Render local templates to stdout to inspect generated YAML
helm template my-webserver ./helm

# Perform a dry-run installation against the live cluster
helm install my-webserver ./helm --dry-run
```

### 2. Installing the Release
```powershell
# Install in default namespace
helm install my-webserver ./helm

# Install in prod namespace with custom replica count & overrides
helm install my-webserver ./helm -n prod --create-namespace --set replicaCount=3
```

### 3. Upgrading Releases
```powershell
# Upgrade release after modifying values.yaml
helm upgrade my-webserver ./helm

# Upgrade with inline value overrides
helm upgrade my-webserver ./helm --set config.appEnv=staging --set service.nodePort=32009
```

### 4. Release History & Rollbacks
```powershell
# List all active Helm releases
helm list -A

# View revision history of a release
helm history my-webserver

# Roll back to revision 1 instantly
helm rollback my-webserver 1
```

### 5. Uninstall & Cleanup
```powershell
# Uninstall release and delete all associated Kubernetes resources
helm uninstall my-webserver

# Uninstall release from prod namespace
helm uninstall my-webserver -n prod
```
