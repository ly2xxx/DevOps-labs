# Helm Hands-On Cheat Sheet

A complete guide to packaging, configuring, and managing our Nginx Webserver application using Helm across multi-environment setups.

---

## 📁 1. Helm Chart Directory Structure

```text
helm/
├── Chart.yaml             # Chart metadata (name, version, appVersion)
├── values.yaml            # Base default configuration
├── values-dev.yaml        # Development environment overrides
├── values-prod.yaml       # Production environment overrides
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

## 🌍 2. Multi-Environment Release Workflow (Dev vs Prod)

### 1. Rendering & Validating Environments Locally

```powershell
# Render DEV environment manifests
helm template webserver-dev ./helm -f ./helm/values-dev.yaml -n dev

# Render PROD environment manifests
helm template webserver-prod ./helm -f ./helm/values-prod.yaml -n prod
```

### 2. Installing Environment Releases

```powershell
# Install DEV release into dev namespace
helm install webserver-dev ./helm -f ./helm/values-dev.yaml -n dev --create-namespace

# Install PROD release into prod namespace
helm install webserver-prod ./helm -f ./helm/values-prod.yaml -n prod --create-namespace
```

### 3. Upgrading Environment Releases

```powershell
# Upgrade DEV with a custom image tag build
helm upgrade webserver-dev ./helm -f ./helm/values-dev.yaml -n dev --set image.tag=1.25.0-alpine

# Upgrade PROD environment safely
helm upgrade webserver-prod ./helm -f ./helm/values-prod.yaml -n prod

helm upgrade --install <release> ./chart -f values-<env>.yaml --set image.tag=$CI_COMMIT_SHA
```

---

## 🚀 3. Essential Helm Commands Reference

### 1. Dry-Run (Validation)

```powershell
# Perform a dry-run installation against the live cluster for Prod
helm install webserver-prod ./helm -f ./helm/values-prod.yaml -n prod --dry-run=client
```

### 2. Inspection & Application Logs

```powershell
# Check Helm release status
helm status webserver-dev -n dev

# View application container logs (by label)
kubectl logs -n dev -l app=webserver-dev-webserver-chart

# Stream application container logs live
kubectl logs -f -n dev -l app=webserver-dev-webserver-chart

# Inspect deployment events & failures
kubectl describe deployment webserver-dev-webserver-chart-deployment -n dev
```

### 3. Release History & Rollbacks

```powershell
# List all active Helm releases across all namespaces
helm list -A

# View revision history of the prod release
helm history webserver-prod -n prod

# Roll back prod to revision 1 instantly
helm rollback webserver-prod 1 -n prod
```

### 4. Uninstall & Cleanup

```powershell
# Uninstall DEV release
helm uninstall webserver-dev -n dev

# Uninstall PROD release
helm uninstall webserver-prod -n prod
```

Using Helm over raw manifests adds three primary operational benefits:

- Environment Parameterization (DRY Configuration): Instead of duplicating whole folders of YAML for Dev, Staging, and Prod, you reuse one set of templates and inject different environment configs (values-dev.yaml, values-prod.yaml) for replicas, resource sizing, and domain names.
- Release Versioning & Instant Rollbacks: Helm tracks your deployments as versioned releases with release metadata. If a bad release breaks production, you can atomically roll back with a single command (helm rollback wiz-scan-service <revision>).
- Automated CI/CD Integration: In pipelines, you can dynamically override specific parameters on the fly during deployment without modifying YAML files directly:
