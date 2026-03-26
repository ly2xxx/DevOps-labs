# Option 1: GitLab CI/CD Pipeline for Admin Token Rotation

**Approach:** Manual rotation in GitLab UI + Automated Vault sync via CI/CD

**Time:** 30-60 minutes  
**Difficulty:** ⭐⭐ Intermediate

---

## 🎯 How It Works

1. **You rotate** the admin token manually in GitLab UI (click "Rotate")
2. **Copy** the new token
3. **Update** GitLab CI variable `NEW_ADMIN_TOKEN`
4. **Trigger** the CI pipeline (manual or scheduled)
5. **Pipeline syncs** new token to Vault automatically
6. **Old token** is revoked after grace period

---

## ✅ Advantages

- ✅ Simple setup (just a CI pipeline)
- ✅ Leverage existing GitLab CI infrastructure
- ✅ Manual control over rotation timing
- ✅ Automated sync (no manual Vault config)
- ✅ Built-in CI/CD audit trail

---

## 📋 Prerequisites

- GitLab project with CI/CD enabled
- Vault instance accessible from GitLab Runner
- GitLab admin token (the one you'll rotate)
- Vault token with write access to plugin config

---

## 🚀 Quick Start

### Step 1: Setup CI/CD Variables

Go to: **Project → Settings → CI/CD → Variables**

Add these variables:

| Variable | Value | Protected | Masked |
|----------|-------|-----------|--------|
| `VAULT_ADDR` | `http://vault:8200` | ✅ | ❌ |
| `VAULT_TOKEN` | (your vault token) | ✅ | ✅ |
| `CURRENT_ADMIN_TOKEN` | (current GitLab admin token) | ✅ | ✅ |
| `NEW_ADMIN_TOKEN` | (leave empty initially) | ✅ | ✅ |

### Step 2: Add Pipeline File

Copy `.gitlab-ci.yml` to your repository root.

### Step 3: Test Sync (Dry Run)

```powershell
# Manually trigger pipeline with dry-run
# In GitLab: CI/CD → Pipelines → Run Pipeline
# Set variable: DRY_RUN=true
```

### Step 4: Perform First Rotation

1. **Rotate in UI:**
   - Go to: GitLab → User Settings → Access Tokens
   - Find your admin token
   - Click "Rotate" button
   - **Copy the new token immediately!**

2. **Update CI Variable:**
   - Settings → CI/CD → Variables
   - Update `NEW_ADMIN_TOKEN` with copied token

3. **Run Pipeline:**
   - CI/CD → Pipelines → Run Pipeline
   - Watch logs for success

4. **Verify:**
   ```powershell
   # Test that Vault plugin still works
   curl http://localhost:5000/creds/test-role
   ```

---

## 📁 Files Overview

### `.gitlab-ci.yml`
Main CI/CD pipeline with stages:
- **validate**: Check environment and connections
- **sync**: Update Vault backend config
- **verify**: Test plugin still works
- **cleanup**: Optionally revoke old token

### `rotate-and-sync.sh`
Bash script for the actual sync operation.

### `test-sync.ps1`
PowerShell script to test locally before deploying.

---

## 🔄 Workflow Diagram

```
┌─────────────────────────────────────────────┐
│  1. Manual Rotation in GitLab UI            │
│     - Click "Rotate" on admin token         │
│     - Copy new token                        │
└────────────────┬────────────────────────────┘
                 │
    ┌────────────▼─────────────┐
    │  2. Update CI Variable   │
    │     NEW_ADMIN_TOKEN      │
    └────────────┬─────────────┘
                 │
    ┌────────────▼─────────────┐
    │  3. Trigger Pipeline     │
    │     (manual or schedule) │
    └────────────┬─────────────┘
                 │
    ┌────────────▼─────────────┐
    │  4. Pipeline Syncs       │
    │     - Validates tokens   │
    │     - Updates Vault      │
    │     - Tests plugin       │
    └────────────┬─────────────┘
                 │
    ┌────────────▼─────────────┐
    │  5. Verification         │
    │     - Plugin works       │
    │     - Old token revoked  │
    └──────────────────────────┘
```

---

## 🧪 Testing Procedure

### Local Testing

```powershell
cd C:\code\DevOps-labs\token-rotation\lab3-admin-token-rotation\option1-cicd

# Set environment
$env:VAULT_ADDR="http://localhost:8200"
$env:VAULT_TOKEN="root"
$env:CURRENT_ADMIN_TOKEN="current-token"
$env:NEW_ADMIN_TOKEN="new-token"
$env:DRY_RUN="true"

# Run test script
.\test-sync.ps1
```

### CI/CD Testing

1. **Dry Run:**
   - Trigger pipeline with `DRY_RUN=true`
   - Check logs for what WOULD happen

2. **Real Run:**
   - Set `DRY_RUN=false` (or omit)
   - Verify Vault config updated

3. **Plugin Test:**
   ```bash
   # In verify stage, pipeline automatically tests
   curl http://localhost:5000/creds/test-role
   ```

---

## ⚙️ Configuration Options

### Rotation Schedule

**Manual (default):**
- Run pipeline when you rotate token

**Scheduled:**
```yaml
# In .gitlab-ci.yml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
```

Set schedule: **CI/CD → Schedules → New Schedule**
- Interval: Monthly (first day of month)
- Variables: (none needed if token already rotated)

### Grace Period

```yaml
# In .gitlab-ci.yml
variables:
  GRACE_PERIOD_HOURS: "48"  # Keep old token for 2 days
```

### Notification

Add to pipeline:
```yaml
notify-success:
  stage: notify
  script:
    - |
      curl -X POST $SLACK_WEBHOOK \
        -d '{"text":"✅ Admin token rotated and synced to Vault"}'
  when: on_success
```

---

## 🛠️ Troubleshooting

### Issue: Pipeline fails at sync stage

**Symptoms:**
```
Error: 403 Forbidden from Vault
```

**Cause:** Vault token lacks permissions

**Fix:**
```bash
# Grant policy to Vault token
vault policy write gitlab-config - <<EOF
path "gitlab/config" {
  capabilities = ["create", "update"]
}
EOF
```

### Issue: New token doesn't work in Vault plugin

**Symptoms:**
```
Error: GitLab API returned 401 Unauthorized
```

**Cause:** New token missing required scopes

**Fix:**
Ensure new token has `api` scope when rotating in UI.

### Issue: Old token still active after cleanup

**Cause:** `REVOKE_OLD_TOKEN` not set

**Fix:**
Add CI variable: `REVOKE_OLD_TOKEN=true`

---

## 📊 CI/CD Pipeline Stages

### Stage 1: Validate
```yaml
validate:
  script:
    - echo "Checking environment..."
    - test -n "$VAULT_ADDR"
    - test -n "$NEW_ADMIN_TOKEN"
    - vault status
```

### Stage 2: Sync
```yaml
sync:
  script:
    - echo "Updating Vault backend config..."
    - ./rotate-and-sync.sh
```

### Stage 3: Verify
```yaml
verify:
  script:
    - echo "Testing plugin..."
    - curl http://plugin:5000/health
```

### Stage 4: Cleanup
```yaml
cleanup:
  script:
    - echo "Revoking old token..."
    - gitlab-token revoke $OLD_TOKEN_ID
  when: manual  # Require approval
```

---

## 🔐 Security Best Practices

1. **Protected Variables:**
   - Always mark tokens as Protected + Masked

2. **Manual Cleanup:**
   - Make old token revocation manual (requires approval)
   - Allows rollback if issues detected

3. **Audit Trail:**
   - All rotations logged in CI/CD history
   - Track who triggered rotation

4. **Testing:**
   - Always dry-run first
   - Verify plugin functionality before cleanup

---

## 🚀 Production Deployment

### Pre-Deployment

- [ ] Test in dev environment first
- [ ] Document rollback procedure
- [ ] Set up alerts for pipeline failures
- [ ] Schedule rotation during maintenance window

### Deployment

1. Add `.gitlab-ci.yml` to repository
2. Configure CI/CD variables
3. Test with dry-run
4. Perform first rotation manually
5. Monitor plugin functionality
6. Schedule future rotations

### Post-Deployment

- [ ] Verify no Vault plugin errors
- [ ] Check old token revoked
- [ ] Update documentation with new process
- [ ] Train team on rotation procedure

---

## 📅 Rotation Schedule Example

**Monthly rotation:**

1. **Day 1 (09:00):** Rotate token in GitLab UI
2. **Day 1 (09:05):** Update `NEW_ADMIN_TOKEN` CI variable
3. **Day 1 (09:10):** Run pipeline → Vault synced
4. **Day 1 (09:15):** Verify plugin works
5. **Day 3 (09:00):** Run cleanup job → Revoke old token

**Grace period:** 48 hours (Day 1-3)

---

## 🎯 Success Criteria

After successful rotation:

✅ New admin token stored in Vault backend config  
✅ Vault plugin generates tokens using new admin token  
✅ Old admin token still works (grace period)  
✅ CI/CD pipeline completed without errors  
✅ All tests passed  
✅ Audit log shows rotation event  

After cleanup:

✅ Old admin token revoked in GitLab  
✅ Only new token active  
✅ No service interruption  

---

## 📚 Next Steps

After mastering Option 1:

1. **Automate trigger:** Use scheduled pipelines instead of manual
2. **Try Option 2:** Full automation with Python scripts
3. **Add monitoring:** Integrate with Prometheus/Grafana
4. **Multi-environment:** Separate dev/staging/prod rotations

---

**Files in this option:**
- `.gitlab-ci.yml` - Pipeline configuration
- `rotate-and-sync.sh` - Sync script (Linux/Mac)
- `test-sync.ps1` - Local testing (Windows)

**Created:** March 2026  
**Difficulty:** ⭐⭐ Intermediate  
**Time:** 30-60 minutes
