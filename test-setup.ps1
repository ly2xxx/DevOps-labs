# Docker Setup Verification Script
# Tests Docker installation and readiness for UBI9-minimal labs

Write-Host "🐳 Docker Labs - Setup Verification" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Test 1: Docker Installation
Write-Host "✓ Checking Docker installation..." -NoNewline
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " PASS" -ForegroundColor Green
        Write-Host "  $dockerVersion" -ForegroundColor Gray
    } else {
        throw "Docker not found"
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Docker is not installed or not in PATH" -ForegroundColor Yellow
    Write-Host "  Install: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    $allGood = $false
}

# Test 2: Docker Daemon
Write-Host "✓ Checking Docker daemon..." -NoNewline
try {
    docker info >$null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " PASS" -ForegroundColor Green
        Write-Host "  Docker Desktop is running" -ForegroundColor Gray
    } else {
        throw "Daemon not running"
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Docker Desktop is not running" -ForegroundColor Yellow
    Write-Host "  Start Docker Desktop from Start menu" -ForegroundColor Yellow
    $allGood = $false
}

# Test 3: UBI9 Access
Write-Host "✓ Checking UBI9 registry access..." -NoNewline
try {
    # Try to pull a minimal test (won't actually download if cached)
    docker pull registry.access.redhat.com/ubi9/ubi-minimal:latest >$null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " PASS" -ForegroundColor Green
        Write-Host "  Can access Red Hat registry" -ForegroundColor Gray
    } else {
        Write-Host " WARN" -ForegroundColor Yellow
        Write-Host "  Cannot pull UBI9 images (may need VPN/proxy)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " WARN" -ForegroundColor Yellow
    Write-Host "  UBI9 registry test failed (may work later)" -ForegroundColor Yellow
}

# Test 4: VSCode (optional)
Write-Host "✓ Checking VSCode (optional)..." -NoNewline
try {
    $codeVersion = code --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " PASS" -ForegroundColor Green
        $versions = $codeVersion -split "`n"
        Write-Host "  VSCode $($versions[0])" -ForegroundColor Gray
    } else {
        throw "VSCode not found"
    }
} catch {
    Write-Host " SKIP" -ForegroundColor Gray
    Write-Host "  VSCode not installed (optional for debugging)" -ForegroundColor Gray
}

# Test 5: Disk Space
Write-Host "✓ Checking disk space..." -NoNewline
try {
    $drive = (Get-Location).Drive.Name
    $disk = Get-PSDrive $drive
    $freeGB = [math]::Round($disk.Free / 1GB, 1)
    if ($freeGB -gt 10) {
        Write-Host " PASS" -ForegroundColor Green
        Write-Host "  ${freeGB}GB available" -ForegroundColor Gray
    } else {
        Write-Host " WARN" -ForegroundColor Yellow
        Write-Host "  Only ${freeGB}GB free (recommend 10GB+)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " WARN" -ForegroundColor Yellow
    Write-Host "  Could not check disk space" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan

# Summary
if ($allGood) {
    Write-Host "✅ All critical checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Ready to start! Next steps:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1. Read QUICKSTART.md (15-minute guide)" -ForegroundColor White
    Write-Host "  2. cd ubi9-minimal-coder" -ForegroundColor White
    Write-Host "  3. docker build -t coder-template:ubi9-basic -f Dockerfile ." -ForegroundColor White
    Write-Host "  4. docker run -it --rm coder-template:ubi9-basic" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "❌ Some checks failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please fix the issues above and run this script again." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "  • QUICKSTART.md - 15-minute getting started guide" -ForegroundColor White
Write-Host "  • README.md - Comprehensive Docker tutorial" -ForegroundColor White
Write-Host "  • CHEATSHEET.md - Quick command reference" -ForegroundColor White
Write-Host "  • ubi9-minimal-coder/ - Real-world case study" -ForegroundColor White
Write-Host ""
