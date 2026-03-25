# Vault + OKD Quick Reference

Essential commands for working with HashiCorp Vault and OKD integration.

---

## 🚀 Quick Start (5 minutes)

```powershell
# 1. Setup Vault with sample secrets
.\setup-vault-secrets.ps1

# 2. Access Vault UI
# Open: http://localhost:8200
# Token: root

# 3. Deploy test app
oc apply -f vault-demo-app.yaml

# 4. Check pod logs
oc logs -n vault-demo -l app=vault-demo -c app
```

---

## 🐳 Docker Commands

### Vault Container Management
```powershell
# Start Vault (dev mode)
docker run -d --name vault-dev -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=root' hashicorp/vault

# Check status
docker ps | Select-String vault

# View logs
docker logs vault-dev

# Execute commands in container
docker exec -it vault-dev sh

# Stop and remove
docker stop vault-dev
docker rm vault-dev
```

### Network
```powershell
# Create network
docker network create vault-net

# List networks
docker network ls

# Remove network
docker network rm vault-net
```

---

## 🔐 Vault CLI Commands

### Setup & Configuration
```bash
# Set environment variables (PowerShell)
$env:VAULT_ADDR="http://127.0.0.1:8200"
$env:VAULT_TOKEN="root"

# Or (inside container)
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# Check status
vault status

# Enable KV v2 secrets engine
vault secrets enable -version=2 -path=secret kv
```

### Secret Operations
```bash
# Create/update secret
vault kv put secret/myapp/database username="user" password="pass"

# Read secret
vault kv get secret/myapp/database
vault kv get -format=json secret/myapp/database

# List secrets
vault kv list secret/myapp

# Delete secret
vault kv delete secret/myapp/database

# Metadata operations
vault kv metadata get secret/myapp/database
vault kv metadata delete secret/myapp/database
```

### Kubernetes Auth
```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
  token_reviewer_jwt="<SA_TOKEN>" \
  kubernetes_host="https://api.crc.testing:6443" \
  kubernetes_ca_cert="<CA_CERT>"

# Create role
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp-sa \
  bound_service_account_namespaces=default \
  policies=myapp-policy \
  ttl=24h

# Test login
vault write auth/kubernetes/login \
  role=myapp \
  jwt=<SERVICE_ACCOUNT_TOKEN>
```

### Policy Management
```bash
# Create policy
vault policy write myapp-policy - <<EOF
path "secret/data/myapp/*" {
  capabilities = ["read"]
}
EOF

# List policies
vault policy list

# Read policy
vault policy read myapp-policy

# Delete policy
vault policy delete myapp-policy
```

### Audit Logging
```bash
# Enable file audit
vault audit enable file file_path=/vault/logs/audit.log

# List audit devices
vault audit list

# View audit log
docker exec vault-dev cat /vault/logs/audit.log

# Disable audit
vault audit disable file
```

---

## ☸️ OpenShift / OKD Commands

### Cluster Management
```powershell
# Start OKD cluster
crc start

# Stop cluster
crc stop

# Check status
crc status

# Get credentials
crc console --credentials

# Open web console
crc console
```

### Authentication
```powershell
# Login as admin
oc login -u kubeadmin https://api.crc.testing:6443

# Login as developer
oc login -u developer https://api.crc.testing:6443

# Get current user
oc whoami

# Get login token
oc whoami -t
```

### Project (Namespace) Management
```powershell
# Create project
oc new-project vault-demo

# Switch project
oc project vault-demo

# List projects
oc projects

# Delete project
oc delete project vault-demo
```

### Service Account Operations
```powershell
# Create service account
oc create serviceaccount vault-auth -n default

# Describe service account
oc describe serviceaccount vault-auth -n default

# Get service account token
$TOKEN_SECRET = oc get serviceaccount vault-auth -o jsonpath='{.secrets[0].name}'
$SA_TOKEN = oc get secret $TOKEN_SECRET -o jsonpath='{.data.token}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Get cluster CA certificate
$CA_CERT = oc config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

### Resource Management
```powershell
# Apply YAML
oc apply -f vault-demo-app.yaml

# Get resources
oc get all -n vault-demo
oc get pods -n vault-demo
oc get deployments -n vault-demo
oc get services -n vault-demo

# Describe resource
oc describe pod <pod-name> -n vault-demo

# Delete resources
oc delete -f vault-demo-app.yaml
oc delete deployment vault-demo-app -n vault-demo

# Scale deployment
oc scale deployment vault-demo-app --replicas=3 -n vault-demo
```

### Pod Operations
```powershell
# Get pod logs
oc logs -n vault-demo <pod-name>

# Get logs from specific container
oc logs -n vault-demo <pod-name> -c vault-agent
oc logs -n vault-demo <pod-name> -c app

# Follow logs
oc logs -n vault-demo <pod-name> -f

# Execute command in pod
oc exec -n vault-demo <pod-name> -- cat /vault/secrets/database

# Interactive shell
oc exec -it -n vault-demo <pod-name> -- sh

# Port forward
oc port-forward -n vault-demo <pod-name> 8080:8080
```

### Secrets Management
```powershell
# List secrets
oc get secrets -n vault-demo

# Describe secret
oc describe secret <secret-name> -n vault-demo

# View secret data
oc get secret <secret-name> -n vault-demo -o yaml

# Create secret from literal
oc create secret generic my-secret --from-literal=key=value -n vault-demo

# Create secret from file
oc create secret generic my-secret --from-file=./secret.txt -n vault-demo

# Delete secret
oc delete secret <secret-name> -n vault-demo
```

### Debugging
```powershell
# Get events
oc get events -n vault-demo --sort-by='.lastTimestamp'

# Describe all pods (shows events)
oc describe pods -n vault-demo

# Check pod status
oc get pods -n vault-demo -o wide

# Get pod YAML
oc get pod <pod-name> -n vault-demo -o yaml

# Check resource usage
oc adm top pods -n vault-demo
oc adm top nodes
```

---

## 🔄 Common Workflows

### Deploy Application with Vault Secrets

```powershell
# 1. Ensure Vault is running
docker ps | Select-String vault

# 2. Create secrets in Vault
docker exec vault-dev vault kv put secret/myapp/config key1=value1 key2=value2

# 3. Create namespace
oc new-project vault-demo

# 4. Create service account
oc create serviceaccount myapp-sa -n vault-demo

# 5. Deploy application
oc apply -f myapp-deployment.yaml

# 6. Verify secrets injected
$POD = oc get pod -n vault-demo -l app=myapp -o jsonpath='{.items[0].metadata.name}'
oc exec -n vault-demo $POD -- cat /vault/secrets/config
```

### Update Secrets and Rotate

```bash
# 1. Update secret in Vault
vault kv put secret/myapp/config key1=new_value

# 2. Restart pods to pick up new secrets
oc rollout restart deployment/myapp -n vault-demo

# 3. Verify new secrets
oc exec -n vault-demo <pod-name> -- cat /vault/secrets/config
```

### Troubleshoot Vault Agent Issues

```powershell
# 1. Check init container logs
oc logs -n vault-demo <pod-name> -c vault-agent-init

# 2. Check sidecar container logs
oc logs -n vault-demo <pod-name> -c vault-agent

# 3. Verify service account token
oc describe sa myapp-sa -n vault-demo

# 4. Test Vault connectivity from pod
oc exec -n vault-demo <pod-name> -- wget -O- http://host.docker.internal:8200/v1/sys/health

# 5. Check pod annotations
oc get pod <pod-name> -n vault-demo -o jsonpath='{.metadata.annotations}' | ConvertFrom-Json
```

---

## 📊 Vault Agent Annotations Reference

Add these to pod template metadata in your deployment:

```yaml
annotations:
  # Enable injection
  vault.hashicorp.com/agent-inject: "true"
  
  # Vault address (use host.docker.internal for Windows Docker Desktop)
  vault.hashicorp.com/agent-inject-address: "http://host.docker.internal:8200"
  
  # Role to use for authentication
  vault.hashicorp.com/role: "myapp"
  
  # Inject secret
  vault.hashicorp.com/agent-inject-secret-<filename>: "secret/data/path/to/secret"
  
  # Template for secret rendering
  vault.hashicorp.com/agent-inject-template-<filename>: |
    {{- with secret "secret/data/path/to/secret" -}}
    export KEY="{{ .Data.data.key }}"
    {{- end }}
  
  # Optional: Preserve case
  vault.hashicorp.com/preserve-secret-case: "true"
  
  # Optional: Run as specific user
  vault.hashicorp.com/agent-run-as-user: "1000"
  
  # Optional: Change secret path
  vault.hashicorp.com/secret-volume-path: "/custom/secrets"
```

---

## 🧪 Testing & Verification

### Health Checks

```bash
# Vault health
curl http://localhost:8200/v1/sys/health

# OKD health
oc get --raw /healthz

# Check all pods running
oc get pods -A --field-selector=status.phase!=Running
```

### Validate Secrets

```powershell
# Check secret exists in Vault
vault kv get secret/myapp/config

# Check secret injected in pod
oc exec -n vault-demo <pod-name> -- ls -la /vault/secrets/
oc exec -n vault-demo <pod-name> -- cat /vault/secrets/config

# Compare values
vault kv get -format=json secret/myapp/config
oc exec -n vault-demo <pod-name> -- cat /vault/secrets/config
```

---

## 🧹 Cleanup

```powershell
# Delete OKD resources
oc delete project vault-demo

# Stop and remove Vault
docker stop vault-dev
docker rm vault-dev
docker network rm vault-net

# Or use cleanup script
.\setup-vault-secrets.ps1 -CleanupOnly
```

---

## 📚 Additional Resources

- **Vault Documentation:** https://developer.hashicorp.com/vault
- **Vault Kubernetes Integration:** https://developer.hashicorp.com/vault/docs/platform/k8s
- **OKD Documentation:** https://docs.okd.io/
- **Full Lab Guide:** [VAULT-SECRETS-INTEGRATION.md](VAULT-SECRETS-INTEGRATION.md)

---

**Last Updated:** March 2026
