# Lab 3: Auto-Rotating Admin Token for Vault Plugin

**The Final Piece:** Automatically rotate the GitLab admin token that powers the Vault dynamic secrets plugin

**Time:** 2-3 hours  
**Difficulty:** Advanced  
**Prerequisites:** Lab 2 completed

---

## 🎯 The Problem This Solves

In **Lab 2**, we built a Vault plugin that generates dynamic GitLab tokens. However, the plugin itself relies on a **long-lived admin token** to create those dynamic tokens.

**Security gap:**
- Admin token never rotates (single point of failure)
- If compromised, attacker can generate unlimited tokens
- Violates zero-trust principles

**This lab's solution:**
- ✅ Automatically rotate the admin token
- ✅ Seamlessly update Vault backend config
- ✅ True zero standing privileges

---

## 📋 What You'll Build

Three different approaches (choose one or try all three):

### **Option 1: GitLab CI/CD Pipeline**
- Manual rotation in UI → Automated Vault sync
- Best for: Organizations with GitLab CI/CD infrastructure
- **Difficulty:** ⭐⭐ Intermediate

### **Option 2: Python Script + Cron**
- Fully automated end-to-end rotation
- Best for: Production environments, minimal infrastructure
- **Difficulty:** ⭐⭐⭐ Advanced

### **Option 3: Self-Rotating Vault Plugin**
- Plugin rotates its own admin token
- Best for: Maximum automation, zero-touch operations
- **Difficulty:** ⭐⭐⭐⭐ Expert

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Rotation Trigger (Weekly/Monthly)                      │
│  - Option 1: GitLab CI (manual + automated sync)        │
│  - Option 2: Cron job (full automation)                 │
│  - Option 3: Plugin self-check (autonomous)             │
└────────────────────┬────────────────────────────────────┘
                     │
          ┌──────────▼──────────┐
          │ GitLab API          │
          │ - Create new token  │
          │ - Revoke old token  │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │ Vault Backend       │
          │ - Update config     │
          │ - New admin token   │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │ Lab 2 Plugin        │
          │ - Continues working │
          │ - Generates tokens  │
          └─────────────────────┘
```

---

## 📂 Lab Structure

```
lab3-admin-token-rotation/
├── README.md (this file)
├── option1-cicd/
│   ├── README.md
│   ├── .gitlab-ci.yml
│   ├── rotate-and-sync.sh
│   └── test-sync.ps1
├── option2-automated/
│   ├── README.md
│   ├── rotate-admin-token.py
│   ├── requirements.txt
│   ├── setup-cron.ps1
│   └── test-rotation.py
└── option3-self-rotating/
    ├── README.md
    ├── enhanced-plugin.py
    ├── plugin-config.yaml
    └── test-auto-rotation.py
```

---

## 🚀 Quick Comparison

| Feature | Option 1 (CI/CD) | Option 2 (Script) | Option 3 (Plugin) |
|---------|------------------|-------------------|-------------------|
| **Setup Time** | 30 min | 1 hour | 2 hours |
| **Manual Steps** | Initial rotation | None | None |
| **Infrastructure** | GitLab CI | Cron + Python | Enhanced plugin |
| **Automation Level** | Semi (trigger + sync) | Full | Full (autonomous) |
| **Complexity** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Best For** | Existing CI/CD | Production | Zero-touch ops |

---

## 🔐 Security Benefits

All three options provide:

✅ **Regular rotation** - Admin token expires every 30-90 days  
✅ **Automatic updates** - Vault always has valid credentials  
✅ **Grace period** - Old token valid during cutover  
✅ **Audit trail** - All rotations logged  
✅ **Zero downtime** - Users never notice rotation  
✅ **True zero-trust** - No long-lived credentials  

---

## 🎓 Which Option Should You Choose?

### **Start with Option 1 if:**
- ✅ You already use GitLab CI/CD
- ✅ You prefer manual trigger with automated sync
- ✅ You want the simplest setup
- ✅ You're comfortable with UI-based workflows

### **Choose Option 2 if:**
- ✅ You want full automation
- ✅ You have cron/scheduled task infrastructure
- ✅ You prefer standalone scripts
- ✅ You need production-ready solution

### **Use Option 3 if:**
- ✅ You want maximum automation
- ✅ The plugin should be self-sufficient
- ✅ You're building a product/service
- ✅ You want zero-touch operations

**Recommended learning path:** 1 → 2 → 3 (progressive complexity)

---

## 📋 Prerequisites

### Required (all options)
- ✅ Lab 2 completed (Vault dynamic secrets plugin)
- ✅ GitLab account with ability to create personal access tokens
- ✅ Vault instance running (dev or production)
- ✅ Python 3.8+ installed

### Option-specific
- **Option 1:** GitLab project with CI/CD enabled
- **Option 2:** Cron or Windows Task Scheduler
- **Option 3:** Python async knowledge (helpful)

---

## 🧪 Testing Strategy

Each option includes:
- ✅ Dry-run mode (test without changes)
- ✅ Local testing scripts
- ✅ Rollback procedures
- ✅ Health checks

**Test workflow:**
1. Run local tests
2. Execute dry-run
3. Perform real rotation (single)
4. Verify Vault still works
5. Enable automation

---

## 🛠️ Troubleshooting

### Common Issues

**Issue: "Token rotation succeeded but Vault plugin fails"**
- **Cause:** Token doesn't have `api` scope
- **Fix:** Ensure new token has all required scopes

**Issue: "Vault says 403 Forbidden after rotation"**
- **Cause:** New token not updated in Vault config
- **Fix:** Check sync script completed successfully

**Issue: "Old tokens piling up in GitLab"**
- **Cause:** Revocation step not running
- **Fix:** Enable `REVOKE_OLD_TOKEN` in script

---

## 🎯 Production Checklist

Before deploying to production:

- [ ] Test rotation end-to-end in dev environment
- [ ] Document rollback procedure
- [ ] Set up monitoring/alerting for rotation failures
- [ ] Configure notification (email/Slack) on success/failure
- [ ] Test with Vault plugin actively serving requests
- [ ] Verify grace period prevents downtime
- [ ] Schedule rotation during maintenance window (first time)
- [ ] Have manual recovery plan ready

---

## 🔄 Rotation Frequency Recommendations

| Environment | Rotation Schedule | Token TTL |
|-------------|-------------------|-----------|
| **Development** | Weekly | 14 days |
| **Staging** | Bi-weekly | 30 days |
| **Production** | Monthly | 90 days |
| **High-Security** | Weekly | 14 days |

**Grace period:** Always keep old token valid for 24-48 hours after rotation

---

## 📊 Monitoring & Metrics

Track these metrics:

```python
# Prometheus metrics example
from prometheus_client import Counter, Gauge, Histogram

admin_token_rotations = Counter('gitlab_admin_token_rotations_total', 'Total admin token rotations')
admin_token_age_days = Gauge('gitlab_admin_token_age_days', 'Age of current admin token')
rotation_duration = Histogram('gitlab_admin_token_rotation_seconds', 'Time to complete rotation')
rotation_failures = Counter('gitlab_admin_token_rotation_failures_total', 'Failed rotations')
```

**Alert thresholds:**
- Token age > 80 days (warn)
- Token age > 85 days (critical)
- Rotation failure (immediate alert)

---

## 🔗 Integration with Labs 1 & 2

This lab complements the previous labs:

```
┌─────────────────────────────────────────────────────┐
│  Lab 1: User Token Rotation via CI/CD              │
│  - Rotates project access tokens                   │
│  - Stores in Vault KV                              │
└─────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  Lab 2: Vault Dynamic Secrets                      │
│  - Vault plugin generates user tokens on-demand    │
│  - Uses admin token to create them                 │
└─────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  Lab 3: Admin Token Auto-Rotation (THIS LAB)       │
│  - Rotates the admin token used by Lab 2           │
│  - Completes the zero-trust cycle                  │
└─────────────────────────────────────────────────────┘
```

**Result:** End-to-end automated secret lifecycle management! 🎉

---

## 🚀 Getting Started

Choose your option and dive in:

1. 📁 [Option 1: GitLab CI/CD Pipeline](option1-cicd/README.md)
2. 📁 [Option 2: Automated Python Script](option2-automated/README.md)
3. 📁 [Option 3: Self-Rotating Plugin](option3-self-rotating/README.md)

---

## 📚 Additional Resources

### GitLab Personal Access Tokens API
- [Create PAT](https://docs.gitlab.com/ee/api/personal_access_tokens.html#create-a-personal-access-token)
- [Rotate PAT](https://docs.gitlab.com/ee/api/personal_access_tokens.html#rotate-a-personal-access-token)
- [Revoke PAT](https://docs.gitlab.com/ee/api/personal_access_tokens.html#revoke-a-personal-access-token)

### Vault Configuration
- [HTTP Backend Configuration](https://developer.hashicorp.com/vault/api-docs)
- [Plugin Lifecycle](https://developer.hashicorp.com/vault/docs/plugins)

### Automation Best Practices
- [GitLab CI/CD Schedules](https://docs.gitlab.com/ee/ci/pipelines/schedules.html)
- [Windows Task Scheduler](https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page)
- [Linux Cron](https://man7.org/linux/man-pages/man5/crontab.5.html)

---

## 🤝 Contributing

Found an improvement? Each option is modular:
- Enhance rotation logic
- Add more notifications channels
- Improve error handling
- Add multi-Vault support

---

**Created:** March 2026  
**Lab Series:** Token Rotation  
**Focus:** Complete zero-trust secret management

---

**Ready to complete the trilogy?** Pick your option and let's build true zero-trust! 🔐🚀
