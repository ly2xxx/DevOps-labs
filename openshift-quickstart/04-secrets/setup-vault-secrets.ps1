# HashiCorp Vault - Quick Setup Script for OKD Integration Lab
# This script sets up Vault in Docker and creates sample secrets for testing
#
# Prerequisites:
# - Docker Desktop running on Windows
# - OKD cluster running (via CRC)
#
# Usage: .\setup-vault-secrets.ps1

param(
    [string]$VaultToken = "root",
    [int]$VaultPort = 8200,
    [switch]$SkipDockerSetup,
    [switch]$CleanupOnly
)

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   HashiCorp Vault Setup for OKD Integration Lab" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Set error handling - use Continue so docker stderr doesn't throw terminating errors
$ErrorActionPreference = "Continue"

# Cleanup function
function Cleanup-Vault {
    Write-Host "CLEANUP: Cleaning up existing Vault resources..." -ForegroundColor Yellow
    
    $container = docker ps -a --filter "name=vault-dev" --format "{{.Names}}" 2>$null
    if ($container -eq "vault-dev") {
        Write-Host "  Stopping Vault container..." -ForegroundColor Gray
        docker stop vault-dev 2>&1 | Out-Null
        Write-Host "  Removing Vault container..." -ForegroundColor Gray
        docker rm vault-dev 2>&1 | Out-Null
    }
    
    $network = docker network ls --filter "name=vault-net" --format "{{.Name}}" 2>$null
    if ($network -eq "vault-net") {
        Write-Host "  Removing Docker network..." -ForegroundColor Gray
        docker network rm vault-net 2>&1 | Out-Null
    }
    
    Write-Host "SUCCESS: Cleanup complete!" -ForegroundColor Green
    Write-Host ""
}

# Exit if cleanup only
if ($CleanupOnly) {
    Cleanup-Vault
    exit 0
}

# Step 1: Setup Docker containers
if (-not $SkipDockerSetup) {
    Write-Host "STEP 1: Setting up Vault in Docker" -ForegroundColor Cyan
    Write-Host "-------------------------------------" -ForegroundColor Cyan
    
    # Cleanup any existing Vault containers
    $existing = docker ps -a --filter "name=vault-dev" --format "{{.Names}}" 2>$null
    if ($existing -eq "vault-dev") {
        Write-Host "WARNING: Found existing vault-dev container. Cleaning up..." -ForegroundColor Yellow
        Cleanup-Vault
    }
    
    # Create Docker network
    Write-Host "  Creating Docker network 'vault-net'..." -ForegroundColor Gray
    docker network create vault-net 2>&1 | Out-Null
    
    # Start Vault container
    Write-Host "  Starting Vault container (dev mode)..." -ForegroundColor Gray
    $containerId = docker run -d `
        --name vault-dev `
        --network vault-net `
        --cap-add=IPC_LOCK `
        -p ${VaultPort}:8200 `
        -e "VAULT_DEV_ROOT_TOKEN_ID=$VaultToken" `
        -e "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200" `
        -e "VAULT_ADDR=http://127.0.0.1:8200" `
        hashicorp/vault:latest
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to start Vault container" -ForegroundColor Red
        exit 1
    }
    
    # Wait for Vault to be ready
    Write-Host "  Waiting for Vault to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
    
    # Verify Vault is running
    try {
        $health = Invoke-WebRequest -Uri "http://localhost:$VaultPort/v1/sys/health" -UseBasicParsing -ErrorAction SilentlyContinue
        Write-Host "SUCCESS: Vault is running on port $VaultPort" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Vault is not responding. Check Docker logs: docker logs vault-dev" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
}

# Step 2: Configure Vault secrets
Write-Host "STEP 2: Creating sample secrets in Vault" -ForegroundColor Cyan
Write-Host "-------------------------------------" -ForegroundColor Cyan

# Set environment variables for vault CLI commands
$env:VAULT_ADDR = "http://127.0.0.1:$VaultPort"
$env:VAULT_TOKEN = $VaultToken

# Note: In Vault dev mode, secret/ is already mounted as KV v2 by default.
# No need to run 'vault secrets enable' - it would fail with "path is already in use".

# Create database credentials secret
Write-Host "  Creating secret: okd-demo/database" -ForegroundColor Gray
docker exec -e VAULT_TOKEN=$VaultToken vault-dev vault kv put secret/okd-demo/database `
    username="db_user" `
    password="super_secret_password_123" `
    host="postgres.example.com" `
    port="5432" | Out-Null

# Create API keys secret
Write-Host "  Creating secret: okd-demo/api-keys" -ForegroundColor Gray
docker exec -e VAULT_TOKEN=$VaultToken vault-dev vault kv put secret/okd-demo/api-keys `
    stripe_key="sk_test_abcdef123456" `
    sendgrid_key="SG.xyz789" | Out-Null

# Create application config secret
Write-Host "  Creating secret: okd-demo/app-config" -ForegroundColor Gray
docker exec -e VAULT_TOKEN=$VaultToken vault-dev vault kv put secret/okd-demo/app-config `
    jwt_secret="jwt_secret_key_xyz_$(Get-Random -Maximum 9999)" `
    encryption_key="32_byte_encryption_key_here!!" | Out-Null

Write-Host "SUCCESS: Secrets created successfully!" -ForegroundColor Green
Write-Host ""

# Step 3: Verify secrets
Write-Host "STEP 3: Verifying secrets" -ForegroundColor Cyan
Write-Host "-------------------------------------" -ForegroundColor Cyan

Write-Host ""
Write-Host "Database credentials:" -ForegroundColor Yellow
docker exec -e VAULT_TOKEN=$VaultToken vault-dev vault kv get -format=json secret/okd-demo/database | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty data | Format-List

Write-Host "API keys:" -ForegroundColor Yellow
docker exec -e VAULT_TOKEN=$VaultToken vault-dev vault kv get -format=json secret/okd-demo/api-keys | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty data | Format-List

Write-Host "App config:" -ForegroundColor Yellow
docker exec -e VAULT_TOKEN=$VaultToken vault-dev vault kv get -format=json secret/okd-demo/app-config | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty data | Format-List

# Step 4: Display next steps
Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "   SUCCESS: Vault Setup Complete!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Vault UI:       http://localhost:$VaultPort" -ForegroundColor Cyan
Write-Host "Root Token:    $VaultToken" -ForegroundColor Cyan
Write-Host "Container:     vault-dev" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Access Vault UI: http://localhost:$VaultPort" -ForegroundColor White
Write-Host "   Login with token: $VaultToken" -ForegroundColor White
Write-Host ""
Write-Host "2. Follow the integration guide:" -ForegroundColor White
Write-Host "   DOCS: VAULT-SECRETS-INTEGRATION.md" -ForegroundColor White
Write-Host ""
Write-Host "3. Configure Kubernetes auth in Vault (Part 3 in guide)" -ForegroundColor White
Write-Host ""
Write-Host "4. Deploy test application:" -ForegroundColor White
Write-Host "   oc apply -f vault-demo-app.yaml" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: This is DEV MODE - data is lost on container restart!" -ForegroundColor Yellow
Write-Host "    For production, use proper storage backend and TLS." -ForegroundColor Yellow
Write-Host ""
Write-Host "CLEANUP: To cleanup: .\setup-vault-secrets.ps1 -CleanupOnly" -ForegroundColor Gray
Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
