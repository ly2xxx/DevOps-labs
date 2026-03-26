# GitLab Secrets Plugin for HashiCorp Vault

Simplified HTTP-based Vault plugin for generating dynamic GitLab project access tokens.

---

## Quick Start

### Windows (PowerShell)

```powershell
# Install Vault (if not already installed)
winget install HashiCorp.Vault

# Set environment variables
$env:VAULT_ADDR="http://127.0.0.1:8200"
$env:VAULT_TOKEN="root"

# Run setup
.\setup_plugin.ps1

# Start plugin server
python gitlab_secrets_plugin.py
```

### Linux/macOS/Git Bash

```bash
# Set environment variables
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"

# Run setup
chmod +x setup_plugin.sh
./setup_plugin.sh

# Start plugin server
python3 gitlab_secrets_plugin.py
```

---

## Testing

### Auto-start for testing

**Windows:**
```powershell
.\setup_plugin.ps1 -TestOnly
```

**Linux/macOS:**
```bash
./setup_plugin.sh --test-only
```

### Run test suite

```powershell
# Set required environment variables
$env:GITLAB_TOKEN="your-gitlab-token"
$env:GITLAB_PROJECT_ID="12345"

# Run tests
python test_plugin.py
```

---

## Files

- **gitlab_secrets_plugin.py** - Plugin implementation (Flask HTTP server)
- **test_plugin.py** - Test suite
- **requirements.txt** - Python dependencies
- **setup_plugin.ps1** - Windows setup script
- **setup_plugin.sh** - Linux/macOS setup script

---

## Usage Example

```powershell
# 1. Configure backend
Invoke-RestMethod -Uri "http://localhost:5000/config" -Method POST `
  -ContentType "application/json" `
  -Body '{"gitlab_url":"https://gitlab.com","token":"your-admin-token"}'

# 2. Create role
Invoke-RestMethod -Uri "http://localhost:5000/roles/my-app" -Method POST `
  -ContentType "application/json" `
  -Body '{"project_id":"12345","scopes":"read_api,read_repository","ttl":3600}'

# 3. Generate dynamic token
$creds = Invoke-RestMethod -Uri "http://localhost:5000/creds/my-app"
$token = $creds.data.token

# 4. Use token
$headers = @{"PRIVATE-TOKEN" = $token}
Invoke-RestMethod -Uri "https://gitlab.com/api/v4/projects/12345" -Headers $headers

# 5. View Roles
Invoke-RestMethod -Uri "http://localhost:5000/roles"

# Example Output:
# data
# ----
# @{keys=System.Object[]}

# 6. View Specific Role Details
Invoke-RestMethod -Uri "http://localhost:5000/roles/my-app"

# Example Output:
# data
# ----
# @{created_at=2026-03-26T23:14:54.750482; project_id=6; project_name=lab-01-basic-pipeline; scopes=System.Object[]; ttl=3600}
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `POST` | `/config` | Configure backend |
| `GET` | `/config` | Get configuration |
| `POST` | `/roles/<name>` | Create role |
| `GET` | `/roles/<name>` | Get role |
| `GET` | `/roles` | List roles |
| `GET` | `/creds/<role>` | Generate credentials |
| `POST` | `/revoke` | Revoke lease |
| `GET` | `/leases` | List active leases |

---

## Production Note

⚠️ This is a **simplified implementation** for learning purposes.

For production use:
- Use Vault's official [Plugin SDK](https://github.com/hashicorp/vault/tree/main/sdk) (Go-based)
- Enable TLS
- Use proper authentication (not root token)
- Implement proper storage backend
- Add comprehensive error handling
- Set up monitoring and logging

---

## See Also

- [Lab 2 README](../README.md) - Full lab guide
- [Main Token Rotation Labs](../../README.md) - Overview of both labs
