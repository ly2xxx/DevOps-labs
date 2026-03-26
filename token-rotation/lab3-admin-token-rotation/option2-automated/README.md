# Option 2: Fully Automated Python Script

**Approach:** Complete end-to-end automation via Python script + cron/scheduler

**Time:** 1-2 hours  
**Difficulty:** ⭐⭐⭐ Advanced

---

## 🎯 How It Works

**Fully autonomous:**
1. Script creates new GitLab admin token via API
2. Updates Vault backend config automatically
3. Tests that plugin still works
4. Revokes old token after grace period
5. All steps automated - zero manual intervention

---

## ✅ Advantages

- ✅ **Zero manual steps** (fully automated)
- ✅ Schedule with cron or Windows Task Scheduler
- ✅ Standalone (no CI/CD infrastructure needed)
- ✅ Production-ready error handling
- ✅ Detailed logging and notifications
- ✅ Dry-run mode for safety

---

## 📋 Prerequisites

- Python 3.8+
- GitLab personal access token with `api` scope (to create new tokens)
- Vault instance with plugin running
- Cron (Linux/Mac) or Task Scheduler (Windows)

---

## 🚀 Quick Start

### Step 1: Install Dependencies

```powershell
cd C:\code\DevOps-labs\token-rotation\lab3-admin-token-rotation\option2-automated
pip install -r requirements.txt
```

### Step 2: Configure Environment

```powershell
# Set environment variables
$env:GITLAB_URL="https://gitlab.com"
$env:GITLAB_ADMIN_TOKEN="glpat-current-admin-token"
$env:VAULT_ADDR="http://localhost:8200"
$env:PLUGIN_URL="http://localhost:5000"
$env:VAULT_TOKEN="root"

# Optional
$env:SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK"
$env:ROTATION_DAYS="30"  # Rotate every 30 days
```

### Step 3: Test Locally (Dry Run)

```powershell
# Dry run - no changes made
python rotate-admin-token.py --dry-run
```

### Step 4: Perform Real Rotation

```powershell
# Real rotation
python rotate-admin-token.py
```

### Step 5: Setup Scheduled Automation

**Windows:**
```powershell
.\setup-cron.ps1
```

**Linux/Mac:**
```bash
chmod +x setup-cron.sh
./setup-cron.sh
```

---

## 📁 Files Overview

### `rotate-admin-token.py`
Main rotation script (400+ lines).

**Features:**
- Creates new GitLab personal access token
- Updates Vault backend config
- Tests plugin functionality
- Revokes old token (with grace period)
- Sends notifications (Slack, email)
- Comprehensive logging

### `requirements.txt`
Python dependencies.

### `setup-cron.ps1` / `setup-cron.sh`
Automated scheduler setup.

### `test-rotation.py`
Test suite for validation.

---

## 🔄 Rotation Workflow

```
┌─────────────────────────────────────────┐
│  1. Check Token Age                     │
│     - Read creation date from state     │
│     - Compare with rotation interval    │
│     - Skip if too soon                  │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  2. Create New Token via GitLab API     │
│     - Personal access token             │
│     - Scopes: api                       │
│     - Expires: 90 days                  │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  3. Update Vault Plugin Config          │
│     - HTTP POST to /config              │
│     - New token stored                  │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  4. Verify Plugin Works                 │
│     - Health check                      │
│     - Test token generation             │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  5. Revoke Old Token                    │
│     - After grace period (48h default)  │
│     - Delete from GitLab                │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  6. Update State File                   │
│     - Save new token ID                 │
│     - Save creation timestamp           │
│     - Save for next rotation            │
└─────────────────────────────────────────┘
```

---

## 🧪 Testing

### Run Test Suite

```powershell
python test-rotation.py
```

**Tests:**
- ✅ Environment validation
- ✅ GitLab API connection
- ✅ Token creation (dry-run)
- ✅ Vault plugin connection
- ✅ Config update simulation
- ✅ State file handling

### Manual Testing

```powershell
# Step-by-step testing
python rotate-admin-token.py --dry-run --verbose

# Test with different intervals
python rotate-admin-token.py --dry-run --rotation-days 7

# Test notifications
python rotate-admin-token.py --dry-run --notify
```

---

## ⚙️ Configuration Options

### Command-Line Arguments

```
Usage: python rotate-admin-token.py [OPTIONS]

Options:
  --dry-run              Test without making changes
  --verbose              Detailed logging
  --force                Force rotation even if not due
  --rotation-days N      Rotate every N days (default: 30)
  --grace-period-hours N Keep old token for N hours (default: 48)
  --no-revoke            Don't revoke old token
  --notify               Send notifications
  --state-file PATH      Custom state file location
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GITLAB_URL` | `https://gitlab.com` | GitLab instance URL |
| `GITLAB_ADMIN_TOKEN` | (required) | Current admin token |
| `VAULT_ADDR` | (required) | Vault server URL |
| `PLUGIN_URL` | `http://localhost:5000` | Plugin HTTP endpoint |
| `VAULT_TOKEN` | (optional) | Vault auth token |
| `ROTATION_DAYS` | `30` | Rotation interval |
| `GRACE_PERIOD_HOURS` | `48` | Old token validity |
| `SLACK_WEBHOOK_URL` | (optional) | Slack notifications |

---

## 📊 State Management

The script maintains state in: `rotation-state.json`

```json
{
  "current_token_id": 12345,
  "created_at": "2026-03-26T10:00:00Z",
  "next_rotation_due": "2026-04-26T10:00:00Z",
  "last_rotation": "2026-03-26T10:00:00Z",
  "rotation_count": 5,
  "grace_period_expires": "2026-03-28T10:00:00Z",
  "old_token_id": 12344
}
```

**Uses:**
- Track when rotation last occurred
- Calculate next rotation date
- Store token IDs for revocation
- Prevent duplicate rotations

---

## 🔔 Notifications

### Slack Integration

```python
# Automatic if SLACK_WEBHOOK_URL set
export SLACK_WEBHOOK_URL="https://hooks.slack.com/..."
python rotate-admin-token.py --notify
```

**Notification events:**
- ✅ Rotation started
- ✅ New token created
- ✅ Vault updated
- ❌ Rotation failed
- 🗑️ Old token revoked

### Email Integration

```python
# Configure in script
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
EMAIL_FROM = "vault@example.com"
EMAIL_TO = "admin@example.com"
```

---

## 🗓️ Scheduling

### Windows Task Scheduler

```powershell
# Run setup script
.\setup-cron.ps1

# Or manually:
$action = New-ScheduledTaskAction -Execute "python" `
    -Argument "C:\path\to\rotate-admin-token.py"

$trigger = New-ScheduledTaskTrigger -Weekly -At "02:00AM"

Register-ScheduledTask -TaskName "VaultAdminTokenRotation" `
    -Action $action -Trigger $trigger
```

### Linux/Mac Cron

```bash
# Edit crontab
crontab -e

# Add line (monthly rotation at 2am on 1st of month)
0 2 1 * * cd /path/to/lab && /usr/bin/python3 rotate-admin-token.py >> /var/log/token-rotation.log 2>&1
```

### Systemd Timer (Linux)

```ini
# /etc/systemd/system/vault-rotation.timer
[Unit]
Description=Vault Admin Token Rotation Timer

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
```

---

## 🛠️ Troubleshooting

### Issue: "Token rotation skipped - not due yet"

**Cause:** Too soon since last rotation

**Fix:** Use `--force` to override:
```powershell
python rotate-admin-token.py --force
```

### Issue: "Failed to create new token"

**Symptoms:**
```
Error: 403 Forbidden from GitLab
```

**Cause:** Current token lacks permissions

**Fix:** Ensure `GITLAB_ADMIN_TOKEN` has `api` scope

### Issue: "Vault config update failed"

**Cause:** Plugin not running or wrong URL

**Fix:**
```powershell
# Check plugin is running
curl http://localhost:5000/health

# Update PLUGIN_URL if different
$env:PLUGIN_URL="http://actual-url:5000"
```

### Issue: "Old token not revoked"

**Cause:** Grace period not expired

**Fix:** Old tokens revoked automatically after grace period. To force:
```powershell
python rotate-admin-token.py --grace-period-hours 0 --force
```

---

## 🔐 Security Considerations

### Token Storage

```python
# Never log or display tokens
logger.info(f"Token created: {token.id}")  # ✅ Log ID
logger.info(f"Token value: {token.token}")  # ❌ Never log value!

# Encrypt state file if storing token values
from cryptography.fernet import Fernet
```

### Permissions

```bash
# Restrict state file access
chmod 600 rotation-state.json
chown vault-user:vault-user rotation-state.json
```

### Monitoring

```python
# Alert on failed rotations
if not rotation_success:
    send_alert(severity="critical", message="Token rotation failed")
```

---

## 📈 Production Deployment

### Pre-Flight Checklist

- [ ] Test dry-run multiple times
- [ ] Verify Vault plugin compatibility
- [ ] Set up monitoring alerts
- [ ] Document rollback procedure
- [ ] Configure notifications
- [ ] Schedule during maintenance window (first time)

### Deployment Steps

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

3. **Test thoroughly:**
   ```bash
   python test-rotation.py
   python rotate-admin-token.py --dry-run
   ```

4. **First rotation:**
   ```bash
   python rotate-admin-token.py --verbose --notify
   ```

5. **Set up scheduler:**
   ```bash
   ./setup-cron.sh
   ```

6. **Monitor logs:**
   ```bash
   tail -f /var/log/vault-rotation.log
   ```

---

## 📊 Metrics & Monitoring

### Prometheus Metrics

```python
from prometheus_client import Counter, Gauge, Histogram

rotation_counter = Counter('vault_admin_token_rotations_total', 'Total rotations')
rotation_failures = Counter('vault_admin_token_rotation_failures', 'Failed rotations')
token_age_days = Gauge('vault_admin_token_age_days', 'Current token age')
rotation_duration = Histogram('vault_admin_token_rotation_seconds', 'Rotation time')
```

### Alerting Rules

```yaml
# Prometheus alert
- alert: TokenRotationFailed
  expr: increase(vault_admin_token_rotation_failures[1h]) > 0
  annotations:
    summary: "Vault admin token rotation failed"

- alert: TokenAgeHigh
  expr: vault_admin_token_age_days > 85
  annotations:
    summary: "Admin token approaching expiry"
```

---

## 🎯 Success Metrics

After successful automation:

✅ **Rotation runs monthly** without manual intervention  
✅ **Zero service interruptions** during rotations  
✅ **All rotations logged** with timestamps  
✅ **Notifications sent** on success/failure  
✅ **Old tokens cleaned up** automatically  
✅ **State tracked accurately** in JSON file  

---

## 📚 Next Steps

1. **Add monitoring:** Integrate with Prometheus/Grafana
2. **Multi-environment:** Separate dev/staging/prod rotations
3. **Try Option 3:** Self-rotating plugin (most advanced)
4. **Customize notifications:** Add PagerDuty, email, etc.

---

**Files in this option:**
- `rotate-admin-token.py` - Main automation script
- `requirements.txt` - Dependencies
- `test-rotation.py` - Test suite
- `setup-cron.ps1` - Windows scheduler setup
- `setup-cron.sh` - Linux/Mac cron setup

**Created:** March 2026  
**Difficulty:** ⭐⭐⭐ Advanced  
**Time:** 1-2 hours
