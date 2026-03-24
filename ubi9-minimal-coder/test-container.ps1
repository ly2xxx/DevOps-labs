# Test UBI9-Minimal Coder Template Containers

param(
    [Parameter()]
    [ValidateSet("basic", "optimized", "claude", "complete")]
    [string]$Version = "basic"
)

$imageName = "coder-template:ubi9-$Version"

Write-Host ""
Write-Host "🧪 Testing $imageName" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Check if image exists
$imageExists = docker images -q $imageName
if (-not $imageExists) {
    Write-Host "❌ Image not found: $imageName" -ForegroundColor Red
    Write-Host "   Run .\build-all.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Image found: $imageName" -ForegroundColor Green
Write-Host ""

# Test 1: Python version
Write-Host "Test 1: Python Version" -ForegroundColor Yellow
Write-Host "  Command: python3 --version" -ForegroundColor Gray
$pythonVersion = docker run --rm $imageName python3 --version
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ PASS: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "  ❌ FAIL: Python not found" -ForegroundColor Red
}
Write-Host ""

# Test 2: User check
Write-Host "Test 2: Non-Root User" -ForegroundColor Yellow
Write-Host "  Command: whoami" -ForegroundColor Gray
$user = docker run --rm $imageName whoami
if ($user -eq "coder") {
    Write-Host "  ✅ PASS: Running as 'coder' user (non-root)" -ForegroundColor Green
} else {
    Write-Host "  ❌ FAIL: Running as '$user' (should be 'coder')" -ForegroundColor Red
}
Write-Host ""

# Test 3: Working directory
Write-Host "Test 3: Working Directory" -ForegroundColor Yellow
Write-Host "  Command: pwd" -ForegroundColor Gray
$workdir = docker run --rm $imageName pwd
if ($workdir -eq "/home/coder") {
    Write-Host "  ✅ PASS: Working directory is /home/coder" -ForegroundColor Green
} else {
    Write-Host "  ❌ FAIL: Working directory is $workdir" -ForegroundColor Red
}
Write-Host ""

# Test 4: pip availability (basic and claude only)
if ($Version -ne "optimized") {
    Write-Host "Test 4: pip Availability" -ForegroundColor Yellow
    Write-Host "  Command: pip --version" -ForegroundColor Gray
    $pipVersion = docker run --rm $imageName pip --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ PASS: pip available" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  WARN: pip not available (expected for optimized)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Test 5: Claude Code CLI (claude and complete versions)
if ($Version -eq "claude" -or $Version -eq "complete") {
    Write-Host "Test 5: Claude Code CLI Installation" -ForegroundColor Yellow
    Write-Host "  Command: claude-code --version" -ForegroundColor Gray
    $claudeVersion = docker run --rm $imageName claude-code --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ PASS: Claude Code CLI available - $claudeVersion" -ForegroundColor Green
    } else {
        Write-Host "  ❌ FAIL: Claude Code CLI not found" -ForegroundColor Red
        Write-Host "  Error: $claudeVersion" -ForegroundColor Red
    }
    Write-Host ""
    
    # Test Node.js
    Write-Host "Test 5b: Node.js Installation" -ForegroundColor Yellow
    Write-Host "  Command: node --version" -ForegroundColor Gray
    $nodeVersion = docker run --rm $imageName node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ PASS: Node.js $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "  ❌ FAIL: Node.js not found" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 6: Python (complete version)
if ($Version -eq "complete") {
    Write-Host "Test 6: Python + Anthropic SDK" -ForegroundColor Yellow
    Write-Host "  Command: python3 -c 'import anthropic'" -ForegroundColor Gray
    docker run --rm $imageName python3 -c "import anthropic" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ PASS: Python Anthropic SDK available" -ForegroundColor Green
    } else {
        Write-Host "  ❌ FAIL: Python Anthropic SDK not found" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 6: Shell access
Write-Host "Test 6: Shell Access" -ForegroundColor Yellow
Write-Host "  Command: /bin/bash -c 'echo Hello'" -ForegroundColor Gray
$shellTest = docker run --rm $imageName /bin/bash -c "echo Hello"
if ($shellTest -eq "Hello") {
    Write-Host "  ✅ PASS: Shell access works" -ForegroundColor Green
} else {
    Write-Host "  ❌ FAIL: Shell access failed" -ForegroundColor Red
}
Write-Host ""

# Test 7: Environment variables
Write-Host "Test 7: Environment Variables" -ForegroundColor Yellow
Write-Host "  Command: env | grep PATH" -ForegroundColor Gray
$pathVar = docker run --rm $imageName env | Select-String "PATH"
if ($pathVar -match "/home/coder/.local/bin") {
    Write-Host "  ✅ PASS: PATH includes /home/coder/.local/bin" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  WARN: PATH might not include user bin directory" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "✅ Testing complete!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 To run interactively:" -ForegroundColor Cyan
Write-Host "   docker run -it --rm $imageName" -ForegroundColor White
Write-Host ""
