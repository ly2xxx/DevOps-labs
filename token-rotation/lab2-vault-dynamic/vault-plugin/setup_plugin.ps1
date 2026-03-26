# HashiCorp Vault GitLab Secrets Plugin - Setup Script (Windows)
# Automates plugin installation and registration with Vault
#
# Prerequisites:
# - Vault server running (dev or production)
# - VAULT_ADDR and VAULT_TOKEN environment variables set
# - Python 3.8+ installed
#
# Usage:
#   .\setup_plugin.ps1

param(
    [switch]$SkipInstall,
    [switch]$TestOnly
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   HashiCorp Vault GitLab Secrets Plugin - Setup" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Cyan
Write-Host ""

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found. Install Python 3.8+ first." -ForegroundColor Red
    exit 1
}

# Check Vault environment variables
if (-not $env:VAULT_ADDR) {
    Write-Host "❌ VAULT_ADDR not set" -ForegroundColor Red
    Write-Host "   Set with: `$env:VAULT_ADDR='http://localhost:8200'" -ForegroundColor Yellow
    exit 1
}

if (-not $env:VAULT_TOKEN) {
    Write-Host "❌ VAULT_TOKEN not set" -ForegroundColor Red
    Write-Host "   Set with: `$env:VAULT_TOKEN='root'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ VAULT_ADDR: $env:VAULT_ADDR" -ForegroundColor Green
Write-Host "✅ VAULT_TOKEN: ***" -ForegroundColor Green
Write-Host ""

# Test Vault connection
Write-Host "🔍 Testing Vault connection..." -ForegroundColor Cyan
try {
    $vaultStatus = vault status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Connected to Vault" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Vault status check returned non-zero, but may be normal for unsealed vault" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Cannot connect to Vault at $env:VAULT_ADDR" -ForegroundColor Red
    Write-Host "   Make sure Vault is running" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Install Python dependencies
if (-not $SkipInstall) {
    Write-Host "📦 Installing Python dependencies..." -ForegroundColor Cyan
    pip install -r requirements.txt --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
    Write-Host ""
}

# Note: This is a simplified HTTP-based plugin
# In production, you would compile a Go-based Vault plugin
Write-Host "ℹ️  This is a simplified HTTP-based plugin implementation" -ForegroundColor Yellow
Write-Host "   For production, use Vault's official Plugin SDK (Go-based)" -ForegroundColor Yellow
Write-Host ""

# Start plugin server in background (for testing)
if ($TestOnly) {
    Write-Host "🧪 Starting plugin server for testing..." -ForegroundColor Cyan
    Write-Host ""
    
    # Start in background
    $job = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        python gitlab_secrets_plugin.py
    }
    
    Write-Host "✅ Plugin server started (Job ID: $($job.Id))" -ForegroundColor Green
    Write-Host "   Listening on http://localhost:5000" -ForegroundColor Green
    Write-Host ""
    
    # Wait for server to start
    Write-Host "⏳ Waiting for server to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    
    # Test plugin health
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:5000/health" -TimeoutSec 5
        if ($response.status -eq "healthy") {
            Write-Host "✅ Plugin server is healthy" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Plugin server not responding" -ForegroundColor Red
        Stop-Job -Job $job
        Remove-Job -Job $job
        exit 1
    }
    
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "   Plugin Setup Complete!" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Configure the backend:" -ForegroundColor White
    Write-Host '   Invoke-RestMethod -Uri "http://localhost:5000/config" -Method POST -ContentType "application/json" -Body ''{"gitlab_url":"https://gitlab.com","token":"your-gitlab-token"}''' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Create a role:" -ForegroundColor White
    Write-Host '   Invoke-RestMethod -Uri "http://localhost:5000/roles/test-role" -Method POST -ContentType "application/json" -Body ''{"project_id":"12345","scopes":"read_api","ttl":3600}''' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Generate credentials:" -ForegroundColor White
    Write-Host '   Invoke-RestMethod -Uri "http://localhost:5000/creds/test-role"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "4. Run tests:" -ForegroundColor White
    Write-Host "   python test_plugin.py" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Plugin Job ID: $($job.Id)" -ForegroundColor Gray
    Write-Host "To stop: Stop-Job -Id $($job.Id); Remove-Job -Id $($job.Id)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    
} else {
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "   Setup Complete!" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Start the plugin server:" -ForegroundColor White
    Write-Host "   python gitlab_secrets_plugin.py" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. In another terminal, run tests:" -ForegroundColor White
    Write-Host "   python test_plugin.py" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Or follow the lab guide in README.md" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Tip: Use '-TestOnly' flag to auto-start plugin for testing" -ForegroundColor Yellow
    Write-Host "   Example: .\setup_plugin.ps1 -TestOnly" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
}
