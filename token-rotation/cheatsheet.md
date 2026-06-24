# HashiCorp Vault Cheat Sheet

Quick reference for HashiCorp Vault CLI commands, server initialization, secrets engines, and plugin administration.

---

## 🔑 Environment Variables
You must set these variables for the CLI to authenticate and communicate with Vault.

```powershell
# Windows PowerShell
$env:VAULT_ADDR="http://localhost:8200"
$env:VAULT_TOKEN="root"

# Linux / macOS Bash
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="root"
```

---

## 🚀 Server Management & Operations

### Run Dev Server
```bash
# Start a local development server (in-memory, unsealed, root token="root")
vault server -dev

# Start Dev Server listening on a specific address
vault server -dev -dev-listen-address="0.0.0.0:8200"
```

### Seal / Unseal Operations
```bash
# Check Vault status (sealed, version, cluster details)
vault status

# Initialize Vault (returns unseal keys and root token)
vault operator init -key-shares=5 -key-threshold=3

# Unseal Vault (run this until threshold is reached)
vault operator unseal <unseal-key-1>
vault operator unseal <unseal-key-2>
vault operator unseal <unseal-key-3>

# Seal Vault immediately
vault operator seal
```

---

## 📦 Secrets Engine Operations

### Engine Administration
```bash
# List all enabled secrets engines
vault secrets list

# Enable a new secrets engine
vault secrets enable -path=kv-v2 kv-v2
vault secrets enable -path=database database

# Disable a secrets engine (destroys all secrets!)
vault secrets disable kv-v2
```

### KV Secrets Engine (Version 2)
```bash
# Put (Write) a secret
vault kv put kv-v2/my-secret username="my-user" password="my-password"

# Get (Read) latest version of a secret
vault kv get kv-v2/my-secret

# Get a specific version of a secret
vault kv get -version=2 kv-v2/my-secret

# List keys under a path
vault kv list kv-v2/

# Delete latest version of a secret
vault kv delete kv-v2/my-secret

# Undelete (Restore) a deleted secret version
vault kv undelete -versions=2 kv-v2/my-secret

# Destroy a version permanently (cannot be restored)
vault kv destroy -versions=2 kv-v2/my-secret
```

---

## 🛡️ Access Control & Policies

```bash
# Write policy from file
vault policy write read-secrets-policy ./my-policy.hcl

# List all policies
vault policy list

# Read details of a policy
vault policy read read-secrets-policy

# Create token associated with a specific policy
vault token create -policy=read-secrets-policy -ttl=24h
```

### Policy File Example (`my-policy.hcl`)
```hcl
path "kv-v2/data/my-secret" {
  capabilities = ["read"]
}
path "kv-v2/data/dev/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

---

## 🔌 Plugin & Custom Backends

```bash
# Register a plugin in Vault's catalog (requires SHA256 sum)
vault write sys/plugins/catalog/secret/my-plugin \
    sha_256="<SHA256_HASH_OF_BINARY>" \
    command="my-plugin-binary"

# Enable a registered plugin at a specific path
vault secrets enable -path=my-plugin-path -plugin-name=my-plugin secret

# Reload a plugin (needed after upgrading the binary)
vault write sys/plugins/reload/backend \
    plugin=my-plugin
```

---

## 🔍 Troubleshooting & Info

```bash
# Print Vault version
vault version

# Get current token details (capabilities, creation time, TTL)
vault token lookup

# Revoke a token
vault token revoke <token-id>
```
