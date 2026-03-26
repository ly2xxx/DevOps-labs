# Local Test Script for Admin Token Sync
# Tests the sync operation before deploying to GitLab CI
#
# Usage:
#   $env:VAULT_ADDR="http://localhost:8200"
#   $env:VAULT_TOKEN="root"
#   $env:NEW_ADMIN_TOKEN="glpat-xxxxx"
#   .\test-sync.ps1

param(
    [switch]$DryRun = $true
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   Admin Token Sync - Local Test" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Check environment variables
Write-Host "🔍 Checking environment..." -ForegroundColor Cyan

$required = @{
    'VAULT_ADDR' = $env:VAULT_ADDR
    'VAULT_TOKEN' = $env:VAULT_TOKEN
    'NEW_ADMIN_TOKEN' = $env:NEW_ADMIN_TOKEN
}

$missing = @()
foreach ($var in $required.Keys) {
    if (-not $required[$var]) {
        $missing += $var
    }
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing required environment variables:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "✅ Environment variables set" -ForegroundColor Green
Write-Host ""

# Test Vault connection
Write-Host "🔍 Testing Vault connection..." -ForegroundColor Cyan
try {
    $vaultHealth = Invoke-RestMethod -Uri "$env:VAULT_ADDR/v1/sys/health" -ErrorAction Stop
    Write-Host "✅ Vault is reachable" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot connect to Vault: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test GitLab token
Write-Host "🔍 Testing new admin token..." -ForegroundColor Cyan
try {
    $headers = @{
        "PRIVATE-TOKEN" = $env:NEW_ADMIN_TOKEN
    }
    $user = Invoke-RestMethod -Uri "https://gitlab.com/api/v4/user" -Headers $headers
    Write-Host "✅ Token is valid (user: $($user.username))" -ForegroundColor Green
} catch {
    Write-Host "❌ Token validation failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Sync to Vault
Write-Host "🔄 Syncing token to Vault..." -ForegroundColor Cyan

$pluginUrl = $env:PLUGIN_URL
if (-not $pluginUrl) {
    $pluginUrl = "http://localhost:5000"
}

if ($DryRun) {
    Write-Host "🔍 [DRY RUN] Would update Vault plugin config with:" -ForegroundColor Yellow
    Write-Host "   URL: $pluginUrl/config" -ForegroundColor Gray
    Write-Host "   gitlab_url: https://gitlab.com" -ForegroundColor Gray
    Write-Host "   token: [NEW_ADMIN_TOKEN]" -ForegroundColor Gray
    Write-Host "   default_ttl: 3600" -ForegroundColor Gray
    Write-Host "   max_ttl: 86400" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ Dry run complete - no changes made" -ForegroundColor Green
} else {
    $config = @{
        gitlab_url = "https://gitlab.com"
        token = $env:NEW_ADMIN_TOKEN
        default_ttl = 3600
        max_ttl = 86400
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$pluginUrl/config" `
            -Method POST `
            -ContentType "application/json" `
            -Body $config
        
        Write-Host "✅ Vault backend config updated" -ForegroundColor Green
        Write-Host ""
        $response.data | ConvertTo-Json | Write-Host
    } catch {
        Write-Host "❌ Failed to update Vault: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "   Test Complete!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "💡 To perform real sync, run:" -ForegroundColor Yellow
    Write-Host "   .\test-sync.ps1 -DryRun:`$false" -ForegroundColor Cyan
}
