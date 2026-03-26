# HashiCorp Vault + OKD Integration Lab

## Overview

This test case demonstrates how to integrate HashiCorp Vault with your OKD cluster to manage secrets externally. Instead of storing secrets directly in OpenShift, applications retrieve them from Vault at runtime.

**Use Cases:**

- ✅ Centralized secret management across multiple clusters
- ✅ Dynamic secrets with automatic rotation
- ✅ Audit trail for secret access
- ✅ Better separation of concerns (secrets managed separately from deployments)

---

## Prerequisites

- OKD cluster running (via CRC as per main README.md)
- Docker Desktop installed on Windows
- `oc` CLI configured and logged in
- Administrator access to OKD cluster

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     OKD Cluster (CRC)                       │
│                                                             │
│  ┌─────────────────┐         ┌─────────────────┐          │
│  │  Application    │         │  Vault Agent    │          │
│  │  Pod            │◄────────┤  Sidecar        │          │
│  └─────────────────┘         └─────────────────┘          │
│                                       │                     │
│                                       │ Token Auth          │
│                                       ▼                     │
└───────────────────────────────────────┼─────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    │    Docker Host (Windows PC)          │
                    │                   │                   │
                    │         ┌─────────▼─────────┐        │
                    │         │  HashiCorp Vault  │        │
                    │         │  Container        │        │
                    │         └───────────────────┘        │
                    │         Port: 8200                    │
                    └─────────────────────────────────────────┘

vault-auth SA token  →  Kubernetes auth role (okd-demo)  →  ACL Policy (okd-demo)  →  Paths allowed
```

---

## Part 1: Set Up HashiCorp Vault

### Step 1.1: Start Vault in Docker

```powershell
# Create a Docker network for Vault
docker network create vault-net

# Run Vault in dev mode (DO NOT use dev mode in production!)
docker run -d `
  --name vault-dev `
  --network vault-net `
  --cap-add=IPC_LOCK `
  -p 8200:8200 `
  -e 'VAULT_DEV_ROOT_TOKEN_ID=root' `
  -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' `
  -e 'VAULT_ADDR=http://127.0.0.1:8200' `
  hashicorp/vault:latest
```

**Note:** Dev mode:

- ✅ Automatically unsealed
- ✅ In-memory storage (data lost on restart)
- ✅ Root token = "root"
- ⚠️ For learning only, NOT production!

### Step 1.2: Verify Vault is Running

```powershell
# Check container status
docker ps | Select-String vault

# Test Vault API
curl http://localhost:8200/v1/sys/health
```

### Step 1.3: Access Vault UI

Open browser: http://localhost:8200

**Login:**

- Method: Token
- Token: `root`

---

## Part 2: Configure Vault for OpenShift

### Step 2.1: Set Up Vault CLI Environment

```powershell
# Set environment variables (PowerShell)
$env:VAULT_ADDR="http://127.0.0.1:8200"
$env:VAULT_TOKEN="root"

# Download vault CLI (if not already installed)
# From: https://developer.hashicorp.com/vault/install
# Or use Docker exec:
docker exec -it -e VAULT_TOKEN=root vault-dev /bin/sh
```

### Step 2.2: Enable KV Secrets Engine

```bash
# Inside Vault container or using vault CLI
vault secrets enable -version=2 -path=secret kv
```

### Step 2.3: Create Sample Secrets

```bash
# Database credentials
vault kv put secret/okd-demo/database \
  username="db_user" \
  password="super_secret_password_123" \
  host="postgres.example.com" \
  port="5432"

# API keys
vault kv put secret/okd-demo/api-keys \
  stripe_key="sk_test_abcdef123456" \
  sendgrid_key="SG.xyz789"

# Application config
vault kv put secret/okd-demo/app-config \
  jwt_secret="jwt_secret_key_xyz" \
  encryption_key="32_byte_encryption_key_here"
```

### Step 2.4: Verify Secrets

```bash
# Read back the secrets
vault kv get secret/okd-demo/database
vault kv get secret/okd-demo/api-keys
```

---

## Part 3: Enable Kubernetes Auth in Vault

### Step 3.1: Configure Kubernetes Authentication

```bash
# Enable Kubernetes auth method
vault auth enable kubernetes

# Get OKD service account token and CA cert
# (Run these from your Windows PowerShell with oc CLI)
```

**On Windows (PowerShell):**

```powershell
# Log in as admin if not already
oc login --token=<kubeadmin-token> --server=https://api.crc.testing:6443

# Create a service account for Vault
oc create serviceaccount vault-auth -n default

# Create a long-lived token secret bound to the service account
# (Required on OKD 4.11+ / Kubernetes 1.24+ - token secrets are no longer auto-created)
@"
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: vault-auth
type: kubernetes.io/service-account-token
"@ | oc apply -f -

# Wait a moment for the token to be populated, then retrieve it
$SA_JWT_TOKEN = oc get secret vault-auth-token -n default -o jsonpath='{.data.token}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Get Kubernetes CA cert
$K8S_CA_CERT = oc config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Get Kubernetes host
$K8S_HOST = oc config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}'

# Output for verification
Write-Host "K8S_HOST: $K8S_HOST"
Write-Host "Token length: $($SA_JWT_TOKEN.Length)"
```

**Back in PowerShell — run from Windows (variables already set above):**

```powershell
# Step 1: Enable Kubernetes auth method in Vault
docker exec -e VAULT_TOKEN=root vault-dev vault auth enable kubernetes

# Step 2: Write CA cert to a temp file inside the container
# (needed because $K8S_CA_CERT is multi-line — can't pass directly as an argument)
$K8S_CA_CERT | docker exec -i vault-dev sh -c 'cat > /tmp/k8s-ca.crt'

# Step 3: Configure Kubernetes auth
# PowerShell interpolates $SA_JWT_TOKEN and $K8S_HOST; CA cert is read from file with @
docker exec -e VAULT_TOKEN=root vault-dev vault write auth/kubernetes/config `
    token_reviewer_jwt="$SA_JWT_TOKEN" `
    kubernetes_host="$K8S_HOST" `
    kubernetes_ca_cert=@/tmp/k8s-ca.crt

# Step 4: Verify
docker exec -e VAULT_TOKEN=root vault-dev vault read auth/kubernetes/config
```

### Step 3.2: Create Vault Policy

```powershell
# Write policy HCL into the container using a PowerShell here-string
$policy = @"
path "secret/data/okd-demo/*" {
  capabilities = ["read"]
}
"@
$policy | docker exec -i vault-dev sh -c 'cat > /tmp/okd-demo-policy.hcl'

# Write policy to Vault
docker exec -e VAULT_TOKEN=root vault-dev vault policy write okd-demo /tmp/okd-demo-policy.hcl

# Verify
docker exec -e VAULT_TOKEN=root vault-dev vault policy read okd-demo
```

### Step 3.3: Create Kubernetes Auth Role

```powershell
docker exec -e VAULT_TOKEN=root vault-dev vault write auth/kubernetes/role/okd-demo `
    bound_service_account_names=app-service-account `
    bound_service_account_namespaces=vault-demo `
    policies=okd-demo `
    ttl=24h

# Verify
docker exec -e VAULT_TOKEN=root vault-dev vault read auth/kubernetes/role/okd-demo
```

---

## Part 4: Deploy Test Application with Vault Integration

### Method A: Using Vault Agent Sidecar Injector

#### Step 4.1: Install Vault Agent Injector in OKD

**On Windows (PowerShell):**

```powershell
# Create namespace
oc new-project vault-demo

# Add Vault Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault Agent Injector (connects to external Vault)
helm install vault hashicorp/vault `
  --namespace vault-demo `
  --set "injector.externalVaultAddr=http://host.docker.internal:8200" `
  --set "global.externalVaultAddr=http://host.docker.internal:8200"
```

**Note:** `host.docker.internal` allows containers in OKD to reach Docker Desktop on Windows host.

#### Step 4.2: Create Service Account

```yaml
# Save as: vault-demo-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: vault-demo
```

Apply:

```powershell
oc apply -f vault-demo-sa.yaml
```

#### Step 4.3: Deploy Sample Application

```yaml
# Save as: vault-demo-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault-demo-app
  namespace: vault-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vault-demo
  template:
    metadata:
      labels:
        app: vault-demo
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-secret-database: "secret/data/okd-demo/database"
        vault.hashicorp.com/agent-inject-template-database: |
          {{- with secret "secret/data/okd-demo/database" -}}
          export DB_USERNAME="{{ .Data.data.username }}"
          export DB_PASSWORD="{{ .Data.data.password }}"
          export DB_HOST="{{ .Data.data.host }}"
          export DB_PORT="{{ .Data.data.port }}"
          {{- end }}
        vault.hashicorp.com/role: "okd-demo"
        vault.hashicorp.com/agent-inject-secret-api-keys: "secret/data/okd-demo/api-keys"
        vault.hashicorp.com/agent-inject-template-api-keys: |
          {{- with secret "secret/data/okd-demo/api-keys" -}}
          export STRIPE_KEY="{{ .Data.data.stripe_key }}"
          export SENDGRID_KEY="{{ .Data.data.sendgrid_key }}"
          {{- end }}
    spec:
      serviceAccountName: app-service-account
      containers:
      - name: app
        image: busybox:latest
        command: ["sh", "-c"]
        args:
          - |
            echo "Vault secrets injected at /vault/secrets/"
            echo "---"
            echo "Database config:"
            cat /vault/secrets/database
            echo "---"
            echo "API keys:"
            cat /vault/secrets/api-keys
            echo "---"
            echo "Sleeping forever... (inspect with: oc exec)"
            sleep infinity
---
apiVersion: v1
kind: Service
metadata:
  name: vault-demo-app
  namespace: vault-demo
spec:
  selector:
    app: vault-demo
  ports:
  - port: 8080
    targetPort: 8080
```

Apply:

```powershell
oc apply -f vault-demo-app.yaml
```

---

### Method B: Using External Secrets Operator (Alternative)

**External Secrets Operator** syncs secrets from Vault directly into Kubernetes Secret objects.

#### Install External Secrets Operator:

```powershell
# Add Helm repo
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Install operator
helm install external-secrets `
  external-secrets/external-secrets `
  -n external-secrets-system `
  --create-namespace
```

#### Create SecretStore:

```yaml
# Save as: vault-secretstore.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: vault-demo
spec:
  provider:
    vault:
      server: "http://host.docker.internal:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "okd-demo"
          serviceAccountRef:
            name: "app-service-account"
```

#### Create ExternalSecret:

```yaml
# Save as: vault-externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: vault-demo-database
  namespace: vault-demo
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: okd-demo/database
      property: username
  - secretKey: password
    remoteRef:
      key: okd-demo/database
      property: password
  - secretKey: host
    remoteRef:
      key: okd-demo/database
      property: host
  - secretKey: port
    remoteRef:
      key: okd-demo/database
      property: port
```

Apply:

```powershell
oc apply -f vault-secretstore.yaml
oc apply -f vault-externalsecret.yaml
```

**Verify Secret Created:**

```powershell
oc get secret database-credentials -n vault-demo -o yaml
```

---

## Part 5: Verify and Test

### Step 5.1: Check Pod Status

```powershell
# List pods (should show vault-agent sidecar)
oc get pods -n vault-demo

# Describe pod to see injected containers
oc describe pod -l app=vault-demo -n vault-demo
```

### Step 5.2: Verify Secrets Are Injected

```powershell
# Get pod name
$POD_NAME = oc get pod -n vault-demo -l app=vault-demo -o jsonpath='{.items[0].metadata.name}'

# Check injected secrets
oc exec -n vault-demo $POD_NAME -- cat /vault/secrets/database
oc exec -n vault-demo $POD_NAME -- cat /vault/secrets/api-keys
```

**Expected Output:**

```bash
export DB_USERNAME="db_user"
export DB_PASSWORD="super_secret_password_123"
export DB_HOST="postgres.example.com"
export DB_PORT="5432"
```

### Step 5.3: Check Vault Audit Logs

```bash
# In Vault container
docker exec -it vault-dev vault audit enable file file_path=/vault/logs/audit.log

# View audit log
docker exec -it vault-dev cat /vault/logs/audit.log
```

---

## Part 6: Advanced Scenarios

### Scenario A: Dynamic Database Credentials

Vault can generate short-lived database credentials:

```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/my-postgresql-database \
  plugin_name=postgresql-database-plugin \
  allowed_roles="my-role" \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/mydb?sslmode=disable" \
  username="vault" \
  password="vault-password"

# Create role for dynamic credentials
vault write database/roles/my-role \
  db_name=my-postgresql-database \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Read dynamic credentials
vault read database/creds/my-role
```

### Scenario B: Secret Rotation

```bash
# Update secret in Vault
vault kv put secret/okd-demo/database \
  username="db_user" \
  password="new_rotated_password_456" \
  host="postgres.example.com" \
  port="5432"

# Vault Agent automatically picks up changes on next refresh
# Or restart pod to force immediate update
oc rollout restart deployment/vault-demo-app -n vault-demo
```

### Scenario C: Multiple Environments

```bash
# Create environment-specific secrets
vault kv put secret/okd-demo/dev/database username="dev_user" password="dev_pass"
vault kv put secret/okd-demo/staging/database username="staging_user" password="staging_pass"
vault kv put secret/okd-demo/prod/database username="prod_user" password="prod_pass"

# Use different roles per environment
vault write auth/kubernetes/role/okd-demo-dev \
  bound_service_account_names=app-service-account \
  bound_service_account_namespaces=vault-demo-dev \
  policies=okd-demo-dev \
  ttl=24h
```

---

## Part 7: Production Considerations

### Security Best Practices

1. **Never use dev mode in production**

   - Use proper storage backend (Consul, etcd, etc.)
   - Enable auto-unsealing
   - Configure TLS/SSL
2. **Principle of Least Privilege**

   - Create specific policies per application
   - Use short TTLs for tokens
   - Regularly rotate credentials
3. **Network Security**

   - Run Vault in private network
   - Use firewall rules
   - Enable mutual TLS
4. **Monitoring & Auditing**

   - Enable audit logging
   - Monitor secret access patterns
   - Set up alerts for suspicious activity

### High Availability Setup

For production Vault cluster:

```bash
# Example 3-node Vault cluster with Raft storage
# Node 1:
vault server -config=/vault/config/config-node1.hcl

# Node 2:
vault server -config=/vault/config/config-node2.hcl

# Node 3:
vault server -config=/vault/config/config-node3.hcl
```

**Recommended:** Use **HCP Vault** (managed service) or **Vault Enterprise** for production.

---

## Troubleshooting

### Issue: Vault Agent Can't Reach Vault

**Symptom:** Init container `vault-agent-init` fails

**Solution:**

```powershell
# Check network connectivity
oc exec -n vault-demo <pod-name> -c vault-agent -- wget -O- http://host.docker.internal:8200/v1/sys/health

# For OKD on Hyper-V, you may need to use host IP instead
# Get your Windows host IP:
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like "*vEthernet*"}
```

### Issue: Authentication Failure

**Symptom:** `permission denied` errors

**Solution:**

```bash
# Verify service account token
oc get secret -n vault-demo
oc describe serviceaccount app-service-account -n vault-demo

# Check Vault role configuration
vault read auth/kubernetes/role/okd-demo

# Test auth manually
vault write auth/kubernetes/login \
  role=okd-demo \
  jwt=<service-account-token>
```

### Issue: Secrets Not Updating

**Solution:**

```powershell
# Force pod restart
oc rollout restart deployment/vault-demo-app -n vault-demo

# Check vault-agent logs
oc logs -n vault-demo <pod-name> -c vault-agent
```

---

## Cleanup

```powershell
# Remove OKD resources
oc delete project vault-demo

# Stop and remove Vault container
docker stop vault-dev
docker rm vault-dev
docker network rm vault-net
```

---

## Additional Resources

### Official Documentation

- [HashiCorp Vault](https://www.vaultproject.io/)
- [Vault Kubernetes Integration](https://developer.hashicorp.com/vault/docs/platform/k8s)
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [External Secrets Operator](https://external-secrets.io/)

### Tutorials

- [Vault on Kubernetes Deployment Guide](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-raft-deployment-guide)
- [Injecting Secrets into Kubernetes Pods](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar)
- [External Secrets with Vault](https://external-secrets.io/latest/provider/hashicorp-vault/)

### Community

- [Vault GitHub](https://github.com/hashicorp/vault)
- [Vault Discuss Forum](https://discuss.hashicorp.com/c/vault/30)

---

## Summary

This lab demonstrated:

✅ Running HashiCorp Vault in Docker✅ Configuring Kubernetes authentication✅ Storing secrets in Vault✅ Two methods to inject secrets into OKD pods:

- Vault Agent Sidecar (dynamic injection)
- External Secrets Operator (synced Kubernetes Secrets)
  ✅ Verifying secret access
  ✅ Understanding production considerations

**Next Steps:**

- Explore dynamic secrets for databases
- Implement secret rotation workflows
- Set up audit logging and monitoring
- Plan for production Vault deployment

---

**Created:** March 2026
**Lab Environment:** OKD (CRC) on Windows + Docker Desktop

---

Happy secret management! 🔐
