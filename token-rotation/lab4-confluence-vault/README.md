# Lab 4: Confluence + Vault Dynamic Database Credentials

**Apply Lab 2 Pattern to Real Application:** Dynamic database credentials for Atlassian Confluence

**Time:** 2-3 hours  
**Difficulty:** ⭐⭐⭐ Advanced  
**Prerequisites:** Understanding of Lab 2 (Dynamic Secrets)

---

## 🎯 What You'll Build

A production-ready integration where:
1. ✅ Confluence requests database credentials from Vault on startup
2. ✅ Vault generates temporary PostgreSQL user (1-24 hour lifespan)
3. ✅ Credentials automatically expire and renew
4. ✅ Zero long-lived database passwords
5. ✅ Complete audit trail of database access
6. ✅ Automatic cleanup of expired users

---

## 📋 The Problem

**Traditional Confluence deployment:**
```xml
<!-- confluence.cfg.xml - STATIC CREDENTIALS! -->
<property name="hibernate.connection.username">confluence_user</property>
<property name="hibernate.connection.password">hardcoded_password_123</property>
```

**Problems:**
- ❌ Password lives forever in config file
- ❌ Shared across all Confluence instances
- ❌ Rotation requires downtime
- ❌ If compromised, attacker has permanent access
- ❌ Hard to track who accessed database

---

## ✅ The Vault Solution

**With Vault database secrets engine:**
```bash
# Confluence startup script
DB_CREDS=$(vault read database/creds/confluence-app)
DB_USER=$(echo $DB_CREDS | jq -r '.username')  # v-conflu-abc123
DB_PASS=$(echo $DB_CREDS | jq -r '.password')  # Temporary password
```

**Benefits:**
- ✅ Credentials generated on-demand
- ✅ Short-lived (12-24 hours)
- ✅ Unique per instance
- ✅ Automatic revocation
- ✅ Full audit logging
- ✅ Zero-downtime rotation

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│  Confluence Application                             │
│  1. Startup: Request DB credentials from Vault     │
│  2. Vault returns: username + password (12h TTL)   │
│  3. Connect to PostgreSQL with temp credentials    │
│  4. After 12h: Credentials auto-revoked            │
└────────────────┬────────────────────────────────────┘
                 │
    ┌────────────▼─────────────┐
    │  HashiCorp Vault         │
    │  ┌────────────────────┐  │
    │  │ Database Engine    │  │
    │  │ - Creates user     │  │
    │  │ - Sets TTL         │  │
    │  │ - Tracks lease     │  │
    │  └────────┬───────────┘  │
    └───────────┼───────────────┘
                │
    ┌───────────▼───────────────┐
    │  PostgreSQL Database      │
    │  ┌──────────────────────┐ │
    │  │ v-conflu-abc123      │ │
    │  │ (expires in 12h)     │ │
    │  └──────────────────────┘ │
    └───────────────────────────┘
```

---

## 📂 Lab Structure

```
lab4-confluence-vault/
├── README.md (this file)
├── docker-compose.yml          # Full stack for testing
├── vault/
│   ├── setup-vault.sh          # Configure Vault database engine
│   ├── policies/
│   │   └── confluence-policy.hcl
│   └── test-database-engine.sh
├── confluence/
│   ├── start-confluence-vault.sh    # Enhanced startup script
│   ├── confluence-vault-template.xml
│   └── Dockerfile.vault-enabled
├── postgres/
│   ├── init-vault-admin.sql    # Create Vault admin user
│   └── pg_hba.conf
└── tests/
    ├── test-integration.py
    ├── test-credential-rotation.sh
    └── verify-security.py
```

---

## 🚀 Quick Start

### Option 1: Full Docker Stack (Recommended for Testing)

```powershell
cd C:\code\DevOps-labs\token-rotation\lab4-confluence-vault

# Start entire stack (Vault + PostgreSQL + Confluence)
docker-compose up -d

# Setup Vault database engine
docker-compose exec vault sh /vault/setup/setup-vault.sh

# Verify Confluence connected with dynamic credentials
docker-compose logs confluence | Select-String "database"
```

### Option 2: Production Setup (Existing Infrastructure)

```bash
# 1. Configure Vault database engine
./vault/setup-vault.sh

# 2. Create PostgreSQL vault admin user
psql -U postgres -f postgres/init-vault-admin.sql

# 3. Modify Confluence startup
cp confluence/start-confluence-vault.sh /opt/atlassian/confluence/bin/

# 4. Restart Confluence
systemctl restart confluence
```

---

## 🔧 Detailed Setup

### Step 1: Configure Vault Database Engine

```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/confluence-postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles="confluence-app,confluence-readonly" \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/confluence?sslmode=disable" \
  username="vault_admin" \
  password="vault_password"

# Verify connection
vault read database/config/confluence-postgres
```

### Step 2: Create Vault Roles

**Read-Write Role (for Confluence application):**

```bash
vault write database/roles/confluence-app \
  db_name=confluence-postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT ALL PRIVILEGES ON DATABASE confluence TO \"{{name}}\"; \
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; \
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="12h" \
  max_ttl="24h"
```

**Read-Only Role (for reporting/analytics):**

```bash
vault write database/roles/confluence-readonly \
  db_name=confluence-postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT CONNECT ON DATABASE confluence TO \"{{name}}\"; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="4h" \
  max_ttl="12h"
```

### Step 3: Create Vault Policy

```hcl
# confluence-policy.hcl
path "database/creds/confluence-app" {
  capabilities = ["read"]
}

path "database/creds/confluence-readonly" {
  capabilities = ["read"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}
```

```bash
vault policy write confluence-policy vault/policies/confluence-policy.hcl

# Create token for Confluence
vault token create -policy=confluence-policy -period=720h
```

### Step 4: Prepare PostgreSQL

```sql
-- Create Vault admin user (used by Vault to create dynamic users)
CREATE USER vault_admin WITH PASSWORD 'vault_password' CREATEROLE;
GRANT ALL PRIVILEGES ON DATABASE confluence TO vault_admin;

-- Verify
\du vault_admin
```

### Step 5: Modify Confluence Startup

**Original startup:**
```bash
/opt/atlassian/confluence/bin/start-confluence.sh
```

**Enhanced with Vault:**
```bash
#!/bin/bash
# start-confluence-vault.sh

set -e

echo "🔐 Requesting database credentials from Vault..."

# Configure Vault client
export VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
export VAULT_TOKEN="${VAULT_TOKEN}"

if [ -z "$VAULT_TOKEN" ]; then
    echo "❌ VAULT_TOKEN not set"
    exit 1
fi

# Request dynamic credentials
CREDS=$(vault read -format=json database/creds/confluence-app)

if [ $? -ne 0 ]; then
    echo "❌ Failed to get credentials from Vault"
    exit 1
fi

# Extract username and password
DB_USER=$(echo $CREDS | jq -r '.data.username')
DB_PASS=$(echo $CREDS | jq -r '.data.password')
LEASE_ID=$(echo $CREDS | jq -r '.lease_id')

echo "✅ Received credentials: $DB_USER (lease: $LEASE_ID)"

# Update Confluence database configuration
export CONFLUENCE_DB_USERNAME="$DB_USER"
export CONFLUENCE_DB_PASSWORD="$DB_PASS"

# Write to config file (if needed)
sed -i "s|<property name=\"hibernate.connection.username\">.*</property>|<property name=\"hibernate.connection.username\">$DB_USER</property>|" \
    /var/atlassian/application-data/confluence/confluence.cfg.xml

sed -i "s|<property name=\"hibernate.connection.password\">.*</property>|<property name=\"hibernate.connection.password\">$DB_PASS</property>|" \
    /var/atlassian/application-data/confluence/confluence.cfg.xml

echo "🚀 Starting Confluence with dynamic database credentials..."

# Start Confluence
exec /opt/atlassian/confluence/bin/start-confluence.sh
```

---

## 🧪 Testing

### Test 1: Verify Dynamic Credentials Work

```bash
# Generate credentials
CREDS=$(vault read database/creds/confluence-app)

# Extract and test
USERNAME=$(echo $CREDS | jq -r '.data.username')
PASSWORD=$(echo $CREDS | jq -r '.data.password')

# Try connecting
psql -h localhost -U $USERNAME -d confluence -c "SELECT version();"

# Should work!
```

### Test 2: Verify TTL and Expiration

```bash
# Generate credentials
CREDS=$(vault read -format=json database/creds/confluence-app)
LEASE_ID=$(echo $CREDS | jq -r '.lease_id')

echo "Lease ID: $LEASE_ID"

# Check lease info
vault lease lookup $LEASE_ID

# Wait for expiration (or manually revoke)
vault lease revoke $LEASE_ID

# Try connecting again - should fail
psql -h localhost -U $USERNAME -d confluence
# Connection should be refused
```

### Test 3: Confluence Integration Test

```powershell
# Start stack
docker-compose up -d

# Wait for Confluence to start
Start-Sleep -Seconds 60

# Check Confluence logs
docker-compose logs confluence | Select-String "database"

# Should see:
# ✅ Received credentials: v-token-conflu-abc123
# ✅ Database connection successful
```

---

## 📊 Monitoring & Operations

### Check Active Database Users

```sql
-- In PostgreSQL
SELECT 
    usename,
    application_name,
    client_addr,
    backend_start,
    state
FROM pg_stat_activity
WHERE usename LIKE 'v-%';

-- Should show temporary Vault-created users
```

### Check Vault Leases

```bash
# List all active leases
vault list sys/leases/lookup/database/creds/confluence-app

# Check specific lease
vault lease lookup <lease-id>

# Manually revoke if needed
vault lease revoke <lease-id>
```

### Renew Credentials (Long-Running Instances)

```bash
# In Confluence startup script, add renewal logic
while true; do
    sleep 10800  # 3 hours
    vault lease renew $LEASE_ID
    echo "✅ Lease renewed: $LEASE_ID"
done &
```

---

## 🔐 Security Best Practices

### 1. Vault Token Management

```bash
# Use AppRole instead of static token
vault auth enable approle

vault write auth/approle/role/confluence \
  token_policies="confluence-policy" \
  token_ttl=1h \
  token_max_ttl=24h

# Get role_id and secret_id
ROLE_ID=$(vault read -field=role_id auth/approle/role/confluence/role-id)
SECRET_ID=$(vault write -field=secret_id -f auth/approle/role/confluence/secret-id)

# Confluence authenticates with AppRole
vault write auth/approle/login role_id=$ROLE_ID secret_id=$SECRET_ID
```

### 2. Network Security

```yaml
# Only allow Confluence to access Vault
# firewall rules or network policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: confluence-vault-access
spec:
  podSelector:
    matchLabels:
      app: confluence
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: vault
    ports:
    - port: 8200
```

### 3. Audit Logging

```bash
# Enable Vault audit log
vault audit enable file file_path=/vault/logs/audit.log

# Monitor database credential requests
cat /vault/logs/audit.log | jq 'select(.request.path == "database/creds/confluence-app")'
```

### 4. Least Privilege

```sql
-- Don't grant ALL PRIVILEGES
-- Grant only what Confluence needs
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "{{name}}";
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO "{{name}}";
```

---

## 🚨 Troubleshooting

### Issue: Confluence fails to start - "Database connection failed"

**Symptoms:**
```
ERROR: Connection refused
```

**Debugging:**
```bash
# Check Vault is accessible from Confluence
docker-compose exec confluence curl -v http://vault:8200/v1/sys/health

# Check Vault token is valid
docker-compose exec confluence vault status

# Check credentials manually
docker-compose exec confluence sh -c '
  CREDS=$(vault read -format=json database/creds/confluence-app)
  echo $CREDS | jq .
'
```

**Common causes:**
- `VAULT_TOKEN` not set
- Vault policy doesn't allow database credential access
- PostgreSQL not accepting connections from dynamic users

### Issue: "permission denied for database confluence"

**Cause:** Vault admin user lacks required permissions

**Fix:**
```sql
-- Grant CREATEROLE to vault_admin
ALTER USER vault_admin CREATEROLE;

-- Grant privileges on database
GRANT ALL PRIVILEGES ON DATABASE confluence TO vault_admin;
```

### Issue: Old database users piling up

**Cause:** Vault not revoking expired users

**Check:**
```sql
SELECT usename FROM pg_user WHERE usename LIKE 'v-%';
```

**Manual cleanup:**
```sql
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT usename FROM pg_user WHERE usename LIKE 'v-%' LOOP
        EXECUTE 'DROP USER IF EXISTS ' || quote_ident(r.usename);
    END LOOP;
END $$;
```

**Fix:** Ensure Vault can connect to PostgreSQL to revoke users

---

## 📈 Production Deployment

### Pre-Production Checklist

- [ ] Vault configured with HA backend (Consul/Raft)
- [ ] PostgreSQL connection tested from Vault
- [ ] Vault admin user has correct privileges
- [ ] Confluence policy tested with test token
- [ ] Startup script modified and tested
- [ ] Credential renewal logic implemented
- [ ] Monitoring and alerts configured
- [ ] Rollback plan documented

### Deployment Steps

1. **Deploy Vault changes:**
   ```bash
   vault secrets enable database
   vault write database/config/confluence-postgres ...
   vault write database/roles/confluence-app ...
   vault policy write confluence-policy ...
   ```

2. **Test credential generation:**
   ```bash
   vault read database/creds/confluence-app
   psql -U <generated-user> -d confluence
   ```

3. **Update Confluence:**
   ```bash
   # Blue-green deployment
   # Deploy new Confluence instance with Vault integration
   # Test thoroughly
   # Switch traffic
   # Decommission old instance
   ```

4. **Monitor:**
   ```bash
   # Watch Vault audit logs
   # Monitor PostgreSQL connections
   # Check Confluence application logs
   ```

---

## 🔄 Credential Rotation Strategy

### Automatic Rotation (Built-in)

Vault automatically rotates credentials every 12 hours:

```
Time 00:00: Confluence starts, gets credentials (valid until 12:00)
Time 11:00: Confluence renews lease (valid until 23:00)
Time 22:00: Confluence renews lease (valid until 10:00 next day)
...
```

**Implement lease renewal:**

```bash
# Background renewal process
vault lease renew $LEASE_ID

# Or use Vault Agent for automatic renewal
vault agent -config=agent-config.hcl
```

### Manual Rotation (Emergency)

```bash
# Revoke current credentials
vault lease revoke -prefix database/creds/confluence-app

# Restart Confluence (gets new credentials)
systemctl restart confluence
```

---

## 📊 Comparison: Before vs After

| Aspect | Before Vault | After Vault |
|--------|--------------|-------------|
| **Credential Lifetime** | Forever | 12 hours |
| **Rotation** | Manual, requires downtime | Automatic, zero downtime |
| **Compromised Creds** | Permanent access | Expires in <12 hours |
| **Audit Trail** | None | Complete (Vault logs) |
| **Per-Instance Creds** | Shared password | Unique per instance |
| **Revocation** | Manual SQL | Automatic via Vault |

---

## 🎓 Key Learnings

After completing this lab:

✅ Understand Vault database secrets engine  
✅ Apply Lab 2 dynamic secrets to real application  
✅ Configure Confluence for external credential sources  
✅ Implement zero-downtime credential rotation  
✅ Monitor and troubleshoot dynamic database credentials  
✅ Deploy production-ready secret management  

---

## 📚 Next Steps

1. **Extend to other Atlassian apps:**
   - Jira (same database engine pattern)
   - Bitbucket
   - Bamboo

2. **Add advanced features:**
   - Automatic credential renewal
   - Multiple database roles (read-only for reporting)
   - Disaster recovery procedures

3. **Integrate with CI/CD:**
   - Terraform to manage Vault configuration
   - Automated testing of database access

---

## 🤝 Integration with Previous Labs

This lab builds on:

- **Lab 2:** Dynamic secrets pattern (applied to databases)
- **Lab 3:** Token rotation (same concept, different target)

**Complete stack:**
```
Lab 1: Rotate user tokens → Store in Vault
Lab 2: Vault generates user tokens dynamically
Lab 3: Auto-rotate admin token for Lab 2
Lab 4: Apply Lab 2 pattern to real app (Confluence)
```

---

**Files in this lab:**
- `docker-compose.yml` - Full testing stack
- `setup-vault.sh` - Vault database engine setup
- `start-confluence-vault.sh` - Enhanced Confluence startup
- `test-integration.py` - Automated testing
- Configuration templates and examples

**Created:** March 2026  
**Difficulty:** ⭐⭐⭐ Advanced  
**Time:** 2-3 hours

---

🎉 **Ready to apply dynamic secrets to production applications!**
