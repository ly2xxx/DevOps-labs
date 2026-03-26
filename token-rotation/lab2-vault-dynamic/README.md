# Lab 2: Vault Dynamic Secrets for GitLab

**Approach:** HashiCorp Vault generates short-lived GitLab tokens on-demand using a custom secrets engine

**Time:** 2-3 hours  
**Difficulty:** Advanced

---

## 🎯 What You'll Build

A production-grade dynamic secrets system where:
1. ✅ Application requests GitLab token from Vault
2. ✅ Vault creates short-lived token (1h-24h TTL)
3. ✅ Token automatically expires (no manual rotation needed)
4. ✅ **Zero standing privileges** - tokens exist only when needed
5. ✅ Complete audit trail in Vault logs
6. ✅ Automatic cleanup (Vault revokes expired tokens)

---

## 📋 Prerequisites

### Required
- HashiCorp Vault (dev instance or production)
- GitLab project with Admin/Owner access
- Python 3.8+ for plugin development
- Docker (optional, for containerized Vault)

### Knowledge Required
- Vault plugin architecture
- Python async programming (basic)
- REST API integration
- GitLab API (project access tokens)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│              Application / Developer                     │
└───────────────────┬─────────────────────────────────────┘
                    │ 1. Request token
                    │    vault read gitlab/creds/my-app
         ┌──────────▼──────────┐
         │   Vault Server      │
         │  ┌──────────────┐  │
         │  │ GitLab Plugin│  │
         │  └──────┬───────┘  │
         └─────────┼───────────┘
                   │ 2. Create token via API
                   │ 3. Return token (TTL: 1h)
                   │
         ┌─────────▼───────────┐
         │   GitLab Server     │
         │  ┌──────────────┐  │
         │  │Project Token │  │
         │  │(auto-expires)│  │
         │  └──────────────┘  │
         └─────────────────────┘
                   │
         (After TTL expires...)
                   │ 4. Vault auto-revokes
                   ▼
         ┌─────────────────────┐
         │ Token Deleted       │
         └─────────────────────┘
```

---

## 🚀 Quick Start

### Step 1: Setup Vault

```powershell
# Start Vault in dev mode with plugin directory
docker run -d --name vault-dynamic `
  -p 8200:8200 `
  -e 'VAULT_DEV_ROOT_TOKEN_ID=root' `
  -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' `
  -v ${PWD}/vault-plugin:/vault/plugins `
  --cap-add=IPC_LOCK `
  hashicorp/vault

# Set environment
$env:VAULT_ADDR="http://127.0.0.1:8200"
$env:VAULT_TOKEN="root"
```

### Step 2: Build & Register Plugin

```powershell
cd C:\code\DevOps-labs\token-rotation\lab2-vault-dynamic\vault-plugin

# Install plugin dependencies
pip install -r requirements.txt

# Register plugin with Vault
.\setup_plugin.sh  # Or setup_plugin.ps1 for Windows
```

### Step 3: Configure GitLab Integration

```powershell
# Configure GitLab backend
vault write gitlab/config `
  gitlab_url="https://gitlab.com" `
  token="your-gitlab-admin-token" `
  default_ttl="1h" `
  max_ttl="24h"

# Create role for specific project
vault write gitlab/roles/my-app `
  project_id="12345" `
  scopes="read_repository,write_repository" `
  ttl="1h"
```

### Step 4: Test Dynamic Token Generation

```powershell
# Request a token
vault read gitlab/creds/my-app

# Output:
# Key                Value
# ---                -----
# lease_id           gitlab/creds/my-app/abc123
# lease_duration     1h
# lease_renewable    true
# token              glpat-xxxxxxxxxx
# token_id           67890
# expires_at         2026-03-26T10:00:00Z
```

### Step 5: Use in Application

```python
# demo-app/app.py
import hvac
import gitlab

# Get token from Vault
client = hvac.Client(url='http://localhost:8200', token='root')
response = client.read('gitlab/creds/my-app')

gitlab_token = response['data']['token']
lease_id = response['lease_id']

# Use token
gl = gitlab.Gitlab('https://gitlab.com', private_token=gitlab_token)
project = gl.projects.get('12345')
print(f"Accessing project: {project.name}")

# Token auto-expires after TTL (1 hour)
# Vault automatically revokes it from GitLab
```

---

## 📁 Lab Files Overview

### `vault-plugin/`
Custom Vault secrets engine for GitLab

**Files:**
- `gitlab_secrets_plugin.py` - Plugin implementation
- `plugin.json` - Plugin metadata
- `setup_plugin.sh` - Installation script
- `test_plugin.py` - Test suite

### `demo-app/`
Sample application demonstrating dynamic token usage

**Files:**
- `app.py` - Flask app using Vault-generated tokens
- `requirements.txt` - Dependencies
- `README.md` - Usage guide

---

## 🔧 Plugin Implementation

### How the Plugin Works

1. **Backend Configuration:**
```python
# Stores GitLab admin credentials
vault write gitlab/config \
  gitlab_url="https://gitlab.com" \
  token="admin-token-with-api-scope"
```

2. **Role Definition:**
```python
# Defines what tokens can be created
vault write gitlab/roles/my-app \
  project_id="12345" \
  scopes="read_api" \
  ttl="1h"
```

3. **Dynamic Token Generation:**
```python
# When requested, plugin:
# 1. Connects to GitLab with admin token
# 2. Creates project access token with specified scopes
# 3. Returns token to requester
# 4. Stores lease_id for revocation
vault read gitlab/creds/my-app
```

4. **Automatic Revocation:**
```python
# When lease expires (TTL reached):
# 1. Vault calls plugin's Revoke() method
# 2. Plugin deletes token from GitLab via API
# 3. Application can no longer use token
```

---

## 🧪 Testing the Plugin

### Test Suite

```powershell
cd vault-plugin
python test_plugin.py
```

**Test scenarios:**
- ✅ Backend configuration
- ✅ Role creation
- ✅ Token generation
- ✅ Token validation (works in GitLab)
- ✅ Automatic expiry
- ✅ Manual revocation
- ✅ Error handling

### Manual Testing

```powershell
# Test 1: Generate token
$TOKEN = (vault read -format=json gitlab/creds/my-app | ConvertFrom-Json).data.token

# Test 2: Use token
$headers = @{"PRIVATE-TOKEN" = $TOKEN}
Invoke-RestMethod -Uri "https://gitlab.com/api/v4/projects/12345" -Headers $headers

# Test 3: Revoke lease
vault lease revoke gitlab/creds/my-app/abc123

# Test 4: Verify token no longer works
Invoke-RestMethod -Uri "https://gitlab.com/api/v4/projects/12345" -Headers $headers
# Should return 401 Unauthorized
```

---

## 🔐 Security Advantages

### vs Static Tokens
| Feature | Static Tokens | Dynamic Tokens |
|---------|---------------|----------------|
| **Lifetime** | Days/months | Hours |
| **Rotation** | Manual | Automatic |
| **Compromise Risk** | High (long-lived) | Low (expires fast) |
| **Revocation** | Manual | Automatic |
| **Audit Trail** | Limited | Complete in Vault |

### Zero Trust Implementation

**Principle:** No standing privileges
- Tokens exist ONLY when needed
- Automatic expiry eliminates rotation burden
- Vault lease mechanism enforces time limits

**Audit Logging:**
```bash
# Every token request/revocation logged
vault audit enable file file_path=/vault/logs/audit.log

# Query who requested tokens
cat /vault/logs/audit.log | jq 'select(.request.path == "gitlab/creds/my-app")'
```

---

## 🎯 Production Deployment

### High Availability Setup

```yaml
# vault-plugin-config.yaml
plugin:
  name: gitlab-secrets
  type: secret
  command: python gitlab_secrets_plugin.py
  sha256: <plugin-hash>

backend_config:
  gitlab_url: https://gitlab.com
  token: ${GITLAB_ADMIN_TOKEN}
  default_ttl: 1h
  max_ttl: 24h
  max_tokens_per_project: 10  # Prevent token exhaustion

roles:
  - name: ci-cd
    project_id: 12345
    scopes: ["read_repository", "write_repository"]
    ttl: 30m  # Short for CI
  
  - name: developer
    project_id: 12345
    scopes: ["read_api", "read_repository"]
    ttl: 8h  # Workday
```

### Monitoring

```python
# metrics.py - Export plugin metrics
from prometheus_client import Counter, Histogram

tokens_created = Counter('gitlab_tokens_created_total', 'Total tokens created')
tokens_revoked = Counter('gitlab_tokens_revoked_total', 'Total tokens revoked')
token_lifetime = Histogram('gitlab_token_lifetime_seconds', 'Token TTL distribution')

# In plugin:
def create_token(self, role):
    token = gitlab_api.create_token(...)
    tokens_created.inc()
    token_lifetime.observe(role.ttl_seconds)
    return token
```

### Backup Strategy

**Critical data:**
- GitLab admin token (encrypted in Vault backend config)
- Role definitions
- Active lease information

**Backup:**
```bash
# Export role definitions
vault read -format=json gitlab/roles/my-app > role-backup.json

# Vault's storage backend handles lease backup automatically
```

---

## 🛠️ Troubleshooting

### Issue: Plugin not loading

**Symptoms:**
```
Error: plugin not found
```

**Debugging:**
```powershell
# Check plugin registration
vault plugin list secret

# Check plugin permissions
docker exec vault-dynamic ls -la /vault/plugins

# View Vault logs
docker logs vault-dynamic
```

**Fix:**
```bash
# Re-register plugin
vault plugin register -sha256=$SHA256 secret gitlab-secrets python /vault/plugins/gitlab_secrets_plugin.py
vault secrets enable -path=gitlab -plugin-name=gitlab-secrets plugin
```

### Issue: Token creation fails with 403

**Cause:** GitLab admin token lacks permissions

**Fix:**
```bash
# Ensure admin token has `api` scope
# Regenerate in GitLab: User Settings → Access Tokens → api scope
vault write gitlab/config token=<new-admin-token>
```

### Issue: Tokens not being revoked

**Cause:** Lease not tracked properly

**Debug:**
```bash
# List active leases
vault list sys/leases/lookup/gitlab/creds

# Manually revoke
vault lease revoke -prefix gitlab/creds
```

---

## 📊 Comparison: Lab 1 vs Lab 2

| Aspect | Lab 1 (CI/CD Rotation) | Lab 2 (Dynamic Secrets) |
|--------|------------------------|-------------------------|
| **Token Lifetime** | 30-90 days | 1-24 hours |
| **Rotation** | Scheduled (weekly/monthly) | On-demand (every request) |
| **Infrastructure** | GitLab CI + Vault KV | Vault Plugin + GitLab API |
| **Complexity** | ⭐⭐ Medium | ⭐⭐⭐⭐ High |
| **Security** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Best For** | Production apps (stable tokens) | High-security (zero-trust) |
| **Setup Time** | 1-2 hours | 2-3 hours |
| **Maintenance** | Low (scheduled job) | Medium (plugin updates) |

**Recommendation:**
- **Lab 1** for most production workloads
- **Lab 2** for high-security environments, compliance requirements, or temporary access patterns

---

## 🚀 Advanced Scenarios

### Scenario 1: Multi-Tenant SaaS

Different customers get tokens for different projects:

```bash
# Customer A
vault write gitlab/roles/customer-a-prod \
  project_id=111 \
  scopes="read_api" \
  ttl=4h

# Customer B
vault write gitlab/roles/customer-b-prod \
  project_id=222 \
  scopes="read_repository,write_repository" \
  ttl=1h
```

### Scenario 2: Break-Glass Access

Emergency admin access with short TTL:

```bash
vault write gitlab/roles/emergency-admin \
  project_id=12345 \
  scopes="api,write_repository,admin" \
  ttl=15m \
  max_ttl=30m

# Require MFA for this role
vault write auth/approle/role/emergency/token-ttl 15m
```

### Scenario 3: CI/CD Integration

Jenkins/GitHub Actions request tokens on each build:

```groovy
// Jenkinsfile
stage('Get GitLab Token') {
    steps {
        script {
            withVault([vaultSecrets: [[path: 'gitlab/creds/ci-cd', secretValues: [[vaultKey: 'token']]]]]) {
                env.GITLAB_TOKEN = GITLAB_TOKEN
            }
        }
    }
}

stage('Deploy') {
    steps {
        sh 'git push https://oauth2:${GITLAB_TOKEN}@gitlab.com/my/repo.git'
    }
}
// Token auto-expires after build
```

---

## 📚 Additional Resources

### Vault Plugin Development
- [Official Plugin Guide](https://developer.hashicorp.com/vault/docs/plugins)
- [Plugin SDK](https://github.com/hashicorp/vault/tree/main/sdk)
- [Example Plugins](https://github.com/hashicorp/vault-guides/tree/master/plugins)

### GitLab API
- [Project Access Tokens API](https://docs.gitlab.com/ee/api/project_access_tokens.html)
- [Token Scopes](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#personal-access-token-scopes)

### Python Libraries
- [python-gitlab](https://python-gitlab.readthedocs.io/)
- [hvac](https://hvac.readthedocs.io/)

---

## 🧹 Cleanup

```powershell
# Disable plugin
vault secrets disable gitlab

# Deregister plugin
vault plugin deregister secret gitlab-secrets

# Stop Vault
docker stop vault-dynamic
docker rm vault-dynamic

# Remove generated tokens from GitLab
# (Or wait for auto-expiry)
```

---

## 🎓 Key Learnings

After completing this lab, you'll understand:

1. ✅ **Dynamic secrets pattern** - Generate credentials on-demand
2. ✅ **Vault plugin architecture** - Extend Vault with custom backends
3. ✅ **Lease management** - Automatic expiry and revocation
4. ✅ **Zero trust principles** - Eliminate standing privileges
5. ✅ **Production patterns** - HA, monitoring, backup strategies

---

**Lab completed!** 🎉

You've built a production-grade dynamic secrets engine. This pattern applies to:
- Cloud credentials (AWS, Azure, GCP)
- Database passwords
- SSH keys
- API tokens for any service

---

**Created:** March 2026  
**Difficulty:** ⭐⭐⭐⭐ Advanced  
**Time:** 2-3 hours  
**Focus:** Zero-trust credential management
