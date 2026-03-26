# Lab 1: CI/CD Scheduled Token Rotation

**Approach:** GitLab CI pipeline automatically rotates project tokens and stores them in HashiCorp Vault

**Time:** 1-2 hours  
**Difficulty:** Beginner-Intermediate

---

## 🎯 What You'll Build

A production-ready GitLab CI/CD pipeline that:
1. ✅ Runs on a schedule (weekly/monthly)
2. ✅ Creates new GitLab project access token
3. ✅ Stores token securely in Vault
4. ✅ Revokes old token after grace period
5. ✅ Sends notifications on success/failure
6. ✅ Maintains audit trail

---

## 📋 Prerequisites

### Required
- GitLab project (gitlab.com or self-hosted) with Maintainer/Owner role
- HashiCorp Vault instance (local dev or remote)
- Python 3.8+ installed locally for testing

### Environment Variables Needed
- `VAULT_ADDR` - Vault server URL
- `VAULT_TOKEN` - Vault authentication token
- `GITLAB_TOKEN` - Initial GitLab token with `api` scope

---

## 🚀 Quick Start

### Step 1: Setup Vault

```powershell
# Start Vault in dev mode (or use existing instance)
docker run -d --name vault-dev -p 8200:8200 `
  -e 'VAULT_DEV_ROOT_TOKEN_ID=root' `
  -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' `
  hashicorp/vault

# Configure environment
$env:VAULT_ADDR="http://127.0.0.1:8200"
$env:VAULT_TOKEN="root"

# Enable KV v2 secrets engine
docker exec vault-dev vault secrets enable -version=2 -path=secret kv

# Create policy for CI/CD
docker exec vault-dev sh -c 'cat > /tmp/gitlab-policy.hcl <<EOF
path "secret/data/gitlab/tokens/*" {
  capabilities = ["create", "update", "read", "list"]
}
EOF'

docker exec vault-dev vault policy write gitlab-rotation /tmp/gitlab-policy.hcl

# Create token for CI/CD (save this!)
docker exec vault-dev vault token create -policy=gitlab-rotation -period=720h
```

Save the token output - you'll need it for GitLab CI variables.

### Step 2: Setup GitLab Repository

```powershell
# Clone this lab to a new GitLab repository
cd C:\code\DevOps-labs\token-rotation\lab1-cicd-rotation

# Initialize git (if not already)
git init
git add .
git commit -m "Initial commit: GitLab token rotation lab"

# Add your GitLab project as remote
git remote add origin https://gitlab.com/YOUR_USERNAME/token-rotation-lab.git
git push -u origin main
```

### Step 3: Configure GitLab CI/CD Variables

Go to your GitLab project:
**Settings** → **CI/CD** → **Variables** → **Add Variable**

Add these variables (all as **Protected** and **Masked**):

| Key | Value | Protected | Masked |
|-----|-------|-----------|--------|
| `VAULT_ADDR` | `http://127.0.0.1:8200` (or your Vault URL) | ✅ | ❌ |
| `VAULT_TOKEN` | (token from Step 1) | ✅ | ✅ |
| `GITLAB_TOKEN` | (your current project token with `api` scope) | ✅ | ✅ |

**Note:** If Vault is not publicly accessible, you'll need to:
- Run Vault with public URL (ngrok, CloudFlare tunnel, etc.)
- OR use GitLab Runner on same network as Vault

### Step 4: Test Locally

```powershell
# Install dependencies
cd C:\code\DevOps-labs\token-rotation\lab1-cicd-rotation
pip install -r requirements.txt

# Set environment variables
$env:VAULT_ADDR="http://127.0.0.1:8200"
$env:VAULT_TOKEN="root"
$env:GITLAB_TOKEN="your-gitlab-token"
$env:GITLAB_PROJECT_ID="your-project-id"  # Found in project settings

# Run test script
python test_local.py
```

Expected output:
```
🔍 Testing Vault connection... ✅
🔍 Testing GitLab connection... ✅
🔍 Testing token creation... ✅
🔍 Testing Vault storage... ✅
🔍 Cleaning up test data... ✅

✅ All tests passed! Ready for production.
```

### Step 5: Trigger Manual Pipeline

```powershell
# Push to GitLab
git push origin main

# Go to: CI/CD → Pipelines → Run Pipeline
# Select branch: main
# Run pipeline manually
```

Check pipeline logs - you should see:
```
✅ Created new GitLab token: 12345
✅ Stored new token in Vault at secret/gitlab/tokens/YOUR_PROJECT_ID
ℹ️ Old token not revoked (REVOKE_OLD_TOKEN not set)
```

### Step 6: Setup Scheduled Pipeline

Go to: **CI/CD** → **Schedules** → **New Schedule**

- **Description:** Weekly Token Rotation
- **Interval Pattern:** Custom (`0 2 * * 1` for every Monday at 2 AM)
- **Cron Timezone:** Your timezone
- **Target branch:** main
- **Variables:** (optional)
  - `REVOKE_OLD_TOKEN` = `true` (to auto-revoke old tokens)

---

## 📁 Lab Files Overview

### `.gitlab-ci.yml`
GitLab CI pipeline configuration

**Key stages:**
- `validate` - Check environment and connections
- `rotate` - Create new token and store in Vault
- `cleanup` - Revoke old token (optional)
- `notify` - Send success/failure notifications

### `rotate_token.py`
Main rotation script

**Features:**
- Connects to GitLab and Vault
- Creates new token with configurable scopes/expiry
- Stores in Vault with metadata
- Optionally revokes old token
- Error handling and logging

### `requirements.txt`
Python dependencies

### `test_local.py`
Local testing script - validates setup before deploying

### `setup.sh` (Bonus)
Bash script for Linux environments

---

## 🔄 How It Works

```
┌─────────────────────────────────────────────────────┐
│  GitLab Scheduled Pipeline (Weekly)                 │
└───────────────────┬─────────────────────────────────┘
                    │
         ┌──────────▼──────────┐
         │  1. Validate Stage  │
         │  - Check Vault conn │
         │  - Check GitLab API │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │  2. Rotate Stage    │
         │  - Create new token │
         │  - Store in Vault   │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │  3. Cleanup Stage   │
         │  - Revoke old token │
         │  (if enabled)       │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │  4. Notify Stage    │
         │  - Send status msg  │
         └─────────────────────┘
```

---

## 🔐 Security Features

### Token Scopes
By default, new tokens get these scopes:
- `api` - Full API access
- `read_repository` - Read repo
- `write_repository` - Write repo

Customize in `rotate_token.py`:
```python
GITLAB_TOKEN_SCOPES = ['read_api', 'read_repository']  # More restrictive
```

### Token Expiry
Default: 90 days

Adjust in `rotate_token.py`:
```python
GITLAB_TOKEN_EXPIRY_DAYS = 30  # Monthly rotation
```

### Grace Period
Old tokens stay valid for 24h after rotation (configurable)

### Audit Trail
All operations logged to:
- GitLab CI job logs
- Vault audit logs (if enabled)
- Vault secret metadata (created_at, rotated_by, etc.)

---

## 🧪 Testing Scenarios

### Scenario 1: First Run (No Existing Token)
```powershell
# Should create token and store in Vault
python rotate_token.py
# Check Vault: docker exec vault-dev vault kv get secret/gitlab/tokens/PROJECT_ID
```

### Scenario 2: Rotation (Existing Token)
```powershell
# Run twice - second run should rotate
python rotate_token.py
python rotate_token.py
# Check Vault - should have new token_id
```

### Scenario 3: Dry Run
```powershell
$env:DRY_RUN="true"
python rotate_token.py
# Should show what WOULD happen without making changes
```

### Scenario 4: Failure Recovery
```powershell
# Set wrong Vault token
$env:VAULT_TOKEN="wrong"
python rotate_token.py
# Should fail gracefully with clear error message
```

---

## 📊 Monitoring & Alerts

### Check Rotation Health

```powershell
# Get current token from Vault
docker exec vault-dev vault kv get -format=json secret/gitlab/tokens/PROJECT_ID | ConvertFrom-Json

# Check expiry
$secret = docker exec vault-dev vault kv get -format=json secret/gitlab/tokens/PROJECT_ID | ConvertFrom-Json
$expires = $secret.data.data.expires_at
Write-Host "Token expires: $expires"
```

### Alert on Failures

Add to `.gitlab-ci.yml`:
```yaml
notify:
  stage: notify
  script:
    - |
      if [ "$CI_JOB_STATUS" == "failed" ]; then
        # Send email/Slack/webhook notification
        echo "Token rotation failed! Check pipeline logs."
      fi
  when: on_failure
```

---

## 🛠️ Troubleshooting

### Issue: "403 Forbidden" when creating token

**Cause:** GitLab token lacks `api` scope

**Fix:**
1. Go to GitLab project → Settings → Access Tokens
2. Create new token with `api` scope
3. Update `GITLAB_TOKEN` CI variable

### Issue: "Permission denied" writing to Vault

**Cause:** Vault token lacks write permission or wrong path

**Fix:**
```bash
# Check Vault policy
docker exec vault-dev vault policy read gitlab-rotation

# Verify token capabilities
docker exec vault-dev vault token capabilities secret/data/gitlab/tokens/test
```

Should show: `["create", "update", "read"]`

### Issue: Pipeline succeeds but token not rotated

**Cause:** Script exited early due to environment check

**Fix:** Check pipeline logs for skip messages:
```
ℹ️ DRY_RUN mode enabled - no changes made
ℹ️ SKIP_ROTATION=true - skipping rotation
```

### Issue: Old tokens piling up in GitLab

**Cause:** `REVOKE_OLD_TOKEN` not set

**Fix:** Add CI variable `REVOKE_OLD_TOKEN=true` or run cleanup:
```python
# cleanup_old_tokens.py (bonus script)
import gitlab
import os

gl = gitlab.Gitlab(os.getenv('GITLAB_URL'), private_token=os.getenv('GITLAB_TOKEN'))
project = gl.projects.get(os.getenv('GITLAB_PROJECT_ID'))

# Delete all tokens older than 90 days
from datetime import datetime, timedelta
cutoff = datetime.now() - timedelta(days=90)

for token in project.access_tokens.list():
    if datetime.fromisoformat(token.created_at.replace('Z', '+00:00')) < cutoff:
        token.delete()
        print(f"Deleted old token: {token.name}")
```

---

## 🎯 Production Checklist

Before deploying to production:

- [ ] Use production Vault instance (not dev mode)
- [ ] Enable Vault TLS
- [ ] Use AppRole instead of static Vault token
- [ ] Set up Vault audit logging
- [ ] Configure pipeline notifications (email/Slack)
- [ ] Test rotation multiple times
- [ ] Document rollback procedure
- [ ] Set up monitoring dashboard
- [ ] Define rotation schedule (weekly recommended)
- [ ] Configure alert thresholds (token expiry < 7 days)

---

## 🔄 Rollback Procedure

If rotation fails:

1. **Identify last working token:**
```bash
docker exec vault-dev vault kv get secret/gitlab/tokens/PROJECT_ID
```

2. **Use old_token_id from Vault metadata:**
```python
# The script stores old_token_id for emergencies
# Manual rollback: Use old token until next rotation
```

3. **Create emergency token manually:**
- Go to GitLab → Settings → Access Tokens
- Create token with same scopes
- Update Vault manually

4. **Update CI variable:**
```
GITLAB_TOKEN = (emergency token)
```

---

## 🚀 Advanced Features

### Multi-Project Rotation

Extend to rotate tokens for multiple projects:

```yaml
# .gitlab-ci.yml
variables:
  PROJECTS: "12345,67890,111213"

rotate:
  script:
    - |
      for project_id in ${PROJECTS//,/ }; do
        export GITLAB_PROJECT_ID=$project_id
        python rotate_token.py
      done
```

### Notification Integration

Add Slack webhook:

```python
# In rotate_token.py after successful rotation
import requests

webhook_url = os.getenv('SLACK_WEBHOOK_URL')
if webhook_url:
    requests.post(webhook_url, json={
        'text': f'✅ GitLab token rotated successfully for project {project_id}'
    })
```

### Metrics & Dashboards

Export metrics to Prometheus:

```python
# metrics.py
from prometheus_client import Counter, Gauge, push_to_gateway

rotation_counter = Counter('gitlab_token_rotations_total', 'Total token rotations')
rotation_failures = Counter('gitlab_token_rotation_failures_total', 'Failed rotations')
token_age_days = Gauge('gitlab_token_age_days', 'Age of current token in days')

# After successful rotation
rotation_counter.inc()
push_to_gateway('prometheus:9091', job='token-rotation', registry=registry)
```

---

## 📚 Next Steps

After completing this lab:

1. **Try Lab 2** - Dynamic secrets approach for comparison
2. **Extend to other secrets** - SSH keys, cloud credentials
3. **Implement monitoring** - Grafana dashboard for token health
4. **Add compliance reporting** - Track rotation history
5. **Multi-environment setup** - Dev/staging/prod pipelines

---

## 🤝 Additional Resources

- [GitLab Project Access Tokens API](https://docs.gitlab.com/ee/api/project_access_tokens.html)
- [Vault KV Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)
- [python-gitlab Documentation](https://python-gitlab.readthedocs.io/)
- [hvac (Vault Python Client)](https://hvac.readthedocs.io/)

---

**Lab completed!** 🎉

You now have a production-ready token rotation pipeline. Continue to [Lab 2](../lab2-vault-dynamic/README.md) for dynamic secrets approach.

---

**Created:** March 2026  
**Difficulty:** ⭐⭐ Intermediate  
**Time:** 1-2 hours
