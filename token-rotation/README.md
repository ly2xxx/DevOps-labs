# GitLab Token Rotation Labs

Two comprehensive labs exploring different approaches to automating GitLab token rotation with HashiCorp Vault.

---

## 📚 Labs Overview

### **Lab 1: CI/CD Scheduled Rotation**
**Approach:** GitLab CI pipeline rotates tokens and stores in Vault  
**Difficulty:** Beginner-Intermediate  
**Time:** 1-2 hours  
**Best for:** Production environments with GitLab CI infrastructure

### **Lab 2: Vault Dynamic Secrets**
**Approach:** Vault generates short-lived GitLab tokens on-demand  
**Difficulty:** Advanced  
**Time:** 2-3 hours  
**Best for:** High-security environments requiring zero-standing-privileges

---

## 🎯 Learning Objectives

By completing these labs, you will:
- ✅ Automate GitLab project token lifecycle management
- ✅ Integrate HashiCorp Vault with GitLab
- ✅ Implement secure credential rotation patterns
- ✅ Understand CI/CD-based vs dynamic secrets approaches
- ✅ Build production-ready automation scripts
- ✅ Apply secrets management best practices

---

## 📋 Prerequisites

### Required Tools
- **GitLab account** (gitlab.com or self-hosted)
- **GitLab project** (any project with Maintainer/Owner access)
- **HashiCorp Vault** (local dev instance or remote)
- **Python 3.8+** with pip
- **Git** CLI
- **Docker** (optional, for local Vault)

### Required Knowledge
- Basic GitLab CI/CD concepts
- REST API fundamentals
- Python scripting basics
- HashiCorp Vault basics (KV secrets engine)

---

## 🚀 Quick Start

### Option 1: Use Docker Vault (Easiest)

```powershell
# Start Vault in dev mode
docker run -d --name vault-dev -p 8200:8200 `
  -e 'VAULT_DEV_ROOT_TOKEN_ID=root' `
  -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' `
  hashicorp/vault

# Verify
$env:VAULT_ADDR="http://127.0.0.1:8200"
$env:VAULT_TOKEN="root"
docker exec vault-dev vault status
```

### Option 2: Use Existing Vault Instance

```powershell
# Set environment variables
$env:VAULT_ADDR="https://your-vault.example.com"
$env:VAULT_TOKEN="your-vault-token"
```

---

## 📂 Lab Structure

```
token-rotation/
├── README.md (this file)
├── lab1-cicd-rotation/
│   ├── README.md
│   ├── .gitlab-ci.yml
│   ├── rotate_token.py
│   ├── requirements.txt
│   ├── test_local.py
│   └── setup.sh
└── lab2-vault-dynamic/
    ├── README.md
    ├── vault-plugin/
    │   ├── gitlab_secrets_plugin.py
    │   ├── setup_plugin.sh
    │   └── test_plugin.py
    ├── demo-app/
    │   ├── app.py
    │   ├── requirements.txt
    │   └── README.md
    └── setup.sh
```

---

## 🎓 Which Lab Should You Start With?

### Start with **Lab 1** if:
- ✅ You have an existing GitLab CI/CD pipeline
- ✅ You want a production-ready solution quickly
- ✅ Monthly/weekly rotation is sufficient
- ✅ You're comfortable with scheduled jobs

### Start with **Lab 2** if:
- ✅ You need maximum security (short-lived credentials)
- ✅ You want dynamic, on-demand token generation
- ✅ You have time to implement custom Vault plugins
- ✅ You're building a zero-trust architecture

**Recommended:** Complete Lab 1 first to understand the basics, then tackle Lab 2 for advanced patterns.

---

## 🔐 Security Best Practices

Both labs follow these security principles:

1. **Least Privilege**
   - Minimal token scopes
   - Time-limited credentials
   - Role-based access control

2. **Defense in Depth**
   - Vault encryption at rest
   - TLS in transit
   - Audit logging enabled

3. **Rotation & Expiry**
   - Regular rotation schedule
   - Automatic expiration
   - Grace periods for cutover

4. **Secrets Never in Code**
   - Environment variables only
   - Vault-stored credentials
   - GitLab CI/CD masked variables

---

## 🧪 Testing Strategy

Each lab includes:
- **Local testing scripts** - Test before deploying to GitLab
- **Dry-run mode** - Validate without making changes
- **Rollback procedures** - Recover from failures
- **Monitoring examples** - Track rotation health

---

## 📖 Additional Resources

### GitLab API Documentation
- [Project Access Tokens API](https://docs.gitlab.com/ee/api/project_access_tokens.html)
- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)
- [Scheduled Pipelines](https://docs.gitlab.com/ee/ci/pipelines/schedules.html)

### HashiCorp Vault Documentation
- [KV Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv)
- [AppRole Auth Method](https://developer.hashicorp.com/vault/docs/auth/approle)
- [Plugin Development](https://developer.hashicorp.com/vault/docs/plugins)

### Python Libraries
- [python-gitlab](https://python-gitlab.readthedocs.io/)
- [hvac (Vault client)](https://hvac.readthedocs.io/)

---

## 🛠️ Troubleshooting

### Common Issues

**Issue: "403 Forbidden" from GitLab API**
- **Cause:** Insufficient token permissions
- **Fix:** Ensure token has `api` scope

**Issue: "Vault connection refused"**
- **Cause:** Vault not running or wrong address
- **Fix:** Check `VAULT_ADDR` and verify Vault is accessible

**Issue: "Token already exists with this name"**
- **Cause:** Previous run didn't complete cleanup
- **Fix:** Manually delete old tokens via GitLab UI

**Issue: Pipeline succeeds but token not in Vault**
- **Cause:** Vault token expired or wrong path
- **Fix:** Check Vault token validity and KV path

---

## 🧹 Cleanup

After completing labs:

```powershell
# Stop Docker Vault
docker stop vault-dev
docker rm vault-dev

# Remove test tokens from GitLab
# Go to: GitLab Project → Settings → Access Tokens → Revoke test tokens

# Clear environment variables
Remove-Item Env:\VAULT_ADDR
Remove-Item Env:\VAULT_TOKEN
Remove-Item Env:\GITLAB_TOKEN
```

---

## 🎯 Next Steps

After completing both labs:

1. **Choose Your Approach**
   - Production: Lab 1 (CI/CD rotation)
   - High-security: Lab 2 (Dynamic secrets)

2. **Implement in Production**
   - Use production Vault instance (not dev mode)
   - Enable TLS for Vault
   - Set up monitoring and alerts
   - Configure backup rotation jobs

3. **Extend the Pattern**
   - Apply to other secret types (SSH keys, cloud credentials)
   - Integrate with other CI/CD platforms (GitHub Actions, Jenkins)
   - Build centralized secrets management dashboard

---

## 📝 Lab Comparison

| Feature | Lab 1: CI/CD Rotation | Lab 2: Dynamic Secrets |
|---------|----------------------|------------------------|
| **Complexity** | ⭐⭐ Moderate | ⭐⭐⭐⭐ Advanced |
| **Setup Time** | 1-2 hours | 2-3 hours |
| **Token Lifetime** | 30-90 days | 1-24 hours |
| **Rotation Frequency** | Weekly/Monthly | On-demand |
| **Infrastructure** | GitLab CI only | Vault plugin required |
| **Security Level** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Maintenance** | Low | Medium |
| **Production Ready** | ✅ Yes | ⚠️ Requires custom plugin |

---

## 🤝 Contributing

Found an issue or improvement? Both labs are designed to be iterative learning experiences. Feel free to:
- Modify scripts for your environment
- Add additional security controls
- Extend to other platforms (GitHub, Bitbucket, etc.)

---

## 📄 License

These labs are provided for educational purposes. Use at your own risk in production environments.

---

**Ready to start?** Choose your lab:
- 📁 [Lab 1: CI/CD Scheduled Rotation](lab1-cicd-rotation/README.md)
- 📁 [Lab 2: Vault Dynamic Secrets](lab2-vault-dynamic/README.md)

---

**Created:** March 2026  
**Environment:** Windows + GitLab + HashiCorp Vault  
**Focus:** Practical, production-ready token rotation patterns

Happy learning! 🚀
