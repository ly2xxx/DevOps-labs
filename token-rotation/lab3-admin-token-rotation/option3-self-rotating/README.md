# Option 3: Self-Rotating Vault Plugin

**Approach:** Vault plugin manages its own admin token rotation autonomously

**Time:** 2-3 hours  
**Difficulty:** ⭐⭐⭐⭐ Expert

---

## 🎯 How It Works

**Fully autonomous - zero external dependencies:**

1. Plugin tracks its own admin token age
2. When token approaches expiry, plugin self-rotates
3. Creates new GitLab token via API
4. Updates its own config in memory
5. Revokes old token automatically
6. All transparent to users - they never know rotation happened

---

## ✅ Advantages

- ✅ **True zero-touch** - Plugin is self-sufficient
- ✅ **No external scheduler** needed
- ✅ **No manual intervention** ever
- ✅ **Automatic recovery** from failures
- ✅ **Built-in health monitoring**
- ✅ **Production-grade** reliability

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│  Enhanced Vault Plugin                          │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  Background Worker Thread                │  │
│  │  - Check token age every hour            │  │
│  │  - Rotate if > 80 days old               │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                                │
│  ┌──────────────▼───────────────────────────┐  │
│  │  Self-Rotation Logic                     │  │
│  │  1. Create new GitLab token              │  │
│  │  2. Update self.admin_token              │  │
│  │  3. Persist to storage                   │  │
│  │  4. Revoke old token                     │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                                │
│  ┌──────────────▼───────────────────────────┐  │
│  │  Standard Plugin Operations              │  │
│  │  - Generate user tokens                  │  │
│  │  - Uses current admin token              │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

- Python 3.8+ with async support
- GitLab account with ability to create PATs
- Vault dev instance (or production with plugin support)
- Understanding of threading/async concepts (helpful)

---

## 🚀 Quick Start

### Step 1: Install Dependencies

```powershell
cd C:\code\DevOps-labs\token-rotation\lab3-admin-token-rotation\option3-self-rotating
pip install -r requirements.txt
```

### Step 2: Configure Plugin

Edit `plugin-config.yaml`:

```yaml
gitlab:
  url: https://gitlab.com
  admin_token: glpat-your-initial-token
  
rotation:
  enabled: true
  check_interval_hours: 1
  rotate_after_days: 80
  token_expiry_days: 90
  
plugin:
  port: 5000
  log_level: INFO
```

### Step 3: Start Enhanced Plugin

```powershell
python enhanced-plugin.py
```

**Plugin will:**
- Start HTTP server on port 5000
- Begin background rotation checker
- Monitor admin token age
- Auto-rotate when threshold reached

### Step 4: Verify Self-Rotation

```powershell
# Watch logs
tail -f plugin.log

# Check rotation status
curl http://localhost:5000/rotation-status
```

---

## 📁 Files Overview

### `enhanced-plugin.py`
Enhanced version of Lab 2 plugin with self-rotation.

**New features:**
- Background worker thread
- Automatic token age monitoring
- Self-rotation logic
- Persistent state management
- Health monitoring endpoint

### `plugin-config.yaml`
Configuration file for rotation behavior.

### `test-auto-rotation.py`
Test suite for self-rotation logic.

---

## 🔄 Self-Rotation Workflow

```
┌─────────────────────────────────────────────────┐
│  Background Worker (runs every hour)            │
└────────────────┬────────────────────────────────┘
                 │
    ┌────────────▼─────────────┐
    │  Check Token Age         │
    │  - Read creation date    │
    │  - Calculate days old    │
    └────────────┬─────────────┘
                 │
        ┌────────▼────────┐
        │  Age > 80 days? │
        └────┬───────┬────┘
             │ No    │ Yes
             │       │
             │    ┌──▼──────────────────┐
             │    │  Trigger Rotation   │
             │    └──┬──────────────────┘
             │       │
             │    ┌──▼──────────────────┐
             │    │  Create New Token   │
             │    │  via GitLab API     │
             │    └──┬──────────────────┘
             │       │
             │    ┌──▼──────────────────┐
             │    │  Update Config      │
             │    │  self.admin_token   │
             │    └──┬──────────────────┘
             │       │
             │    ┌──▼──────────────────┐
             │    │  Persist State      │
             │    │  to storage         │
             │    └──┬──────────────────┘
             │       │
             │    ┌──▼──────────────────┐
             │    │  Revoke Old Token   │
             │    └──┬──────────────────┘
             │       │
             ▼       ▼
    ┌────────────────────────────────┐
    │  Continue Normal Operations    │
    └────────────────────────────────┘
```

---

## 🧪 Testing Self-Rotation

### Simulate Token Age

```python
# In test-auto-rotation.py
def test_forced_rotation():
    # Temporarily set token age to 81 days
    plugin.state['token_created_at'] = (datetime.now() - timedelta(days=81)).isoformat()
    
    # Trigger check
    plugin.check_and_rotate()
    
    # Verify rotation occurred
    assert plugin.state['rotation_count'] > 0
```

### Monitor Rotation Events

```powershell
# Watch rotation logs in real-time
Get-Content plugin.log -Tail 50 -Wait | Select-String "rotation"

# Check rotation status endpoint
$status = Invoke-RestMethod -Uri "http://localhost:5000/rotation-status"
$status | ConvertTo-Json
```

### Manual Trigger (Testing)

```powershell
# Force rotation via API (for testing)
Invoke-RestMethod -Uri "http://localhost:5000/force-rotation" -Method POST
```

---

## ⚙️ Configuration Options

### `plugin-config.yaml`

```yaml
gitlab:
  url: https://gitlab.com
  admin_token: glpat-xxx  # Initial token
  token_name_prefix: "vault-auto"
  
rotation:
  enabled: true
  check_interval_hours: 1  # How often to check
  rotate_after_days: 80    # Rotate when token is this old
  token_expiry_days: 90    # New tokens expire after this
  grace_period_hours: 48   # Keep old token for this long
  max_retry_attempts: 3    # Retry on failure
  retry_interval_minutes: 10
  
notifications:
  slack_webhook: null  # Optional
  email_to: null       # Optional
  
plugin:
  port: 5000
  log_level: INFO
  log_file: plugin.log
  state_file: plugin-state.json
  
storage:
  type: file  # or 'vault' for production
  path: ./state
```

---

## 🔐 Security Features

### State Encryption

```python
# Plugin encrypts sensitive state
from cryptography.fernet import Fernet

class EncryptedStateManager:
    def __init__(self, key):
        self.cipher = Fernet(key)
    
    def save_state(self, state):
        encrypted = self.cipher.encrypt(json.dumps(state).encode())
        with open('state.enc', 'wb') as f:
            f.write(encrypted)
```

### Token Handling

```python
# Never log token values
logger.info(f"Token {token.id} created")  # ✅
logger.info(f"Token value: {token.token}")  # ❌

# Clear from memory after use
new_token_value = token.token
# ... use it ...
del new_token_value
```

### Audit Trail

```python
# Every rotation logged
{
  "event": "token_rotation",
  "timestamp": "2026-03-26T10:00:00Z",
  "old_token_id": 12345,
  "new_token_id": 12346,
  "triggered_by": "automatic",
  "success": true
}
```

---

## 📊 Monitoring & Observability

### Health Endpoint

```powershell
# Check plugin health
curl http://localhost:5000/health

# Response:
{
  "status": "healthy",
  "admin_token_age_days": 25,
  "next_rotation_due": "2026-04-21T10:00:00Z",
  "rotation_enabled": true,
  "last_rotation": "2026-03-26T10:00:00Z"
}
```

### Rotation Status Endpoint

```powershell
curl http://localhost:5000/rotation-status

# Response:
{
  "current_token_id": 12346,
  "token_age_days": 5,
  "rotation_count": 12,
  "last_rotation": "2026-03-21T10:00:00Z",
  "next_check": "2026-03-26T11:00:00Z",
  "auto_rotation_enabled": true
}
```

### Metrics Export

```python
# Prometheus metrics
from prometheus_client import start_http_server, Gauge, Counter

token_age_gauge = Gauge('vault_admin_token_age_days', 'Admin token age in days')
rotation_counter = Counter('vault_admin_token_rotations_total', 'Total auto-rotations')

# Update in background worker
token_age_gauge.set(plugin.get_token_age_days())
```

---

## 🛠️ Troubleshooting

### Issue: Rotation not happening

**Symptoms:**
- Token age > 80 days
- No rotation logs

**Debug:**
```python
# Check rotation worker status
curl http://localhost:5000/worker-status

# Check config
curl http://localhost:5000/config | jq '.rotation'

# Enable debug logging
export LOG_LEVEL=DEBUG
python enhanced-plugin.py
```

**Common causes:**
- `rotation.enabled: false` in config
- Worker thread crashed
- GitLab API errors (check logs)

### Issue: Rotation fails repeatedly

**Symptoms:**
```
ERROR: Failed to rotate token: 403 Forbidden
```

**Cause:** Current admin token lost `api` scope

**Fix:**
```yaml
# Manually update config with new token
gitlab:
  admin_token: glpat-new-token-with-api-scope
```

### Issue: Old tokens not revoked

**Cause:** Revocation step failing

**Debug:**
```powershell
# Check plugin logs
Select-String "revoke" plugin.log

# Manually revoke via GitLab UI
# User Settings → Access Tokens → Revoke
```

---

## 🎯 Production Deployment

### Pre-Production

- [ ] Test self-rotation in dev environment
- [ ] Verify background worker stability
- [ ] Test failure recovery (kill/restart plugin)
- [ ] Monitor for memory leaks (long-running test)
- [ ] Configure notifications
- [ ] Set up monitoring dashboards

### Production Setup

1. **Deploy with systemd:**
```ini
# /etc/systemd/system/vault-plugin.service
[Unit]
Description=Vault GitLab Plugin with Self-Rotation
After=network.target

[Service]
Type=simple
User=vault
WorkingDirectory=/opt/vault-plugin
ExecStart=/usr/bin/python3 enhanced-plugin.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

2. **Configure monitoring:**
```yaml
# Prometheus scrape config
scrape_configs:
  - job_name: 'vault-plugin'
    static_configs:
      - targets: ['localhost:5000']
```

3. **Set up alerts:**
```yaml
- alert: TokenRotationFailed
  expr: time() - vault_last_rotation_timestamp > 86400*90
  annotations:
    summary: "Token not rotated in 90 days"
```

---

## 🔄 Comparison with Other Options

| Feature | Option 1 (CI/CD) | Option 2 (Script) | Option 3 (Plugin) |
|---------|------------------|-------------------|-------------------|
| **Manual steps** | UI rotation | None | None |
| **External scheduler** | GitLab CI | Cron | Built-in |
| **Infrastructure** | GitLab CI | Cron + Python | Plugin only |
| **Autonomy** | Low | Medium | High |
| **Complexity** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Maintenance** | Medium | Low | Very Low |
| **Recovery** | Manual | Retry logic | Auto-retry |
| **Best for** | Existing CI/CD | Standalone | Products |

---

## 📈 Success Metrics

After deployment:

✅ **Plugin runs continuously** without restarts  
✅ **Tokens rotate automatically** every 80-90 days  
✅ **Zero manual intervention** required  
✅ **All rotations logged** and audited  
✅ **Users never notice** rotation events  
✅ **Failures self-recover** automatically  

---

## 🎓 Learning Outcomes

After completing this option:

- ✅ Understand background workers in Python
- ✅ Implement self-healing systems
- ✅ Build production-grade automation
- ✅ Apply zero-trust principles
- ✅ Design autonomous services

---

## 📚 Next Steps

1. **Production hardening:** Add retry logic, error recovery
2. **Distributed deployment:** Multiple plugin instances
3. **Advanced monitoring:** Grafana dashboards
4. **Multi-GitLab support:** Manage multiple instances

---

**Files in this option:**
- `enhanced-plugin.py` - Self-rotating plugin implementation
- `plugin-config.yaml` - Configuration file
- `test-auto-rotation.py` - Test suite
- `requirements.txt` - Dependencies

**Created:** March 2026  
**Difficulty:** ⭐⭐⭐⭐ Expert  
**Time:** 2-3 hours

---

**🎉 Congratulations!** You've mastered the most advanced token rotation pattern - a fully autonomous, self-managing system!
