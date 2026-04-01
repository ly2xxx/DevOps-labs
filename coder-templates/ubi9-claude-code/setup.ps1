# Quick setup script for UBI9 Claude Code Coder template
# Automates image build and template creation

$ErrorActionPreference = "Stop"

Write-Host "=== UBI9 Claude Code Coder Template Setup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
try {
    docker version | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check Coder CLI
try {
    coder version | Out-Null
    Write-Host "✅ Coder CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Coder CLI not found. Please install: https://coder.com/docs/cli" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Build Docker image
Write-Host "🐳 Building Docker image..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..."
Write-Host ""

$dockerfilePath = "C:\code\DevOps-labs\docker-dx-extension\ubi9-minimal-coder"

if (!(Test-Path $dockerfilePath)) {
    Write-Host "❌ Dockerfile not found at: $dockerfilePath" -ForegroundColor Red
    exit 1
}

Push-Location $dockerfilePath

try {
    docker build -f Dockerfile.with-claude-code -t ubi9-minimal-coder:with-claude-code .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker image built successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Docker build failed" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Write-Host ""

# Step 3: Verify image
Write-Host "🔍 Verifying Docker image..." -ForegroundColor Yellow
$image = docker images ubi9-minimal-coder:with-claude-code --format "{{.Repository}}:{{.Tag}}"

if ($image) {
    Write-Host "✅ Image found: $image" -ForegroundColor Green
    
    # Show image size
    $size = docker images ubi9-minimal-coder:with-claude-code --format "{{.Size}}"
    Write-Host "   Size: $size" -ForegroundColor Gray
} else {
    Write-Host "❌ Image not found" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Create/update Coder template
Write-Host "📦 Creating Coder template..." -ForegroundColor Yellow

$templateDir = "C:\code\DevOps-labs\coder-templates\ubi9-claude-code"
Push-Location $templateDir

try {
    # Check if template already exists
    $existingTemplate = coder templates list 2>$null | Select-String "ubi9-claude-code"
    
    if ($existingTemplate) {
        Write-Host "Template already exists. Updating..." -ForegroundColor Yellow
        coder templates push ubi9-claude-code --directory .
    } else {
        Write-Host "Creating new template..." -ForegroundColor Yellow
        coder templates create ubi9-claude-code --directory .
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Coder template ready" -ForegroundColor Green
    } else {
        Write-Host "❌ Template creation failed" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Write-Host ""

# Step 5: Instructions
Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Create a workspace:" -ForegroundColor White
Write-Host "   coder create my-claude-workspace --template ubi9-claude-code" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Or use Coder UI:" -ForegroundColor White
Write-Host "   http://localhost:7080" -ForegroundColor Gray
Write-Host ""
Write-Host "3. SSH into workspace:" -ForegroundColor White
Write-Host "   coder ssh my-claude-workspace" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Set Claude API key in workspace:" -ForegroundColor White
Write-Host "   export ANTHROPIC_API_KEY='your-key'" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Start using Claude Code:" -ForegroundColor White
Write-Host "   claude-code" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 Full docs: C:\code\DevOps-labs\coder-templates\ubi9-claude-code\README.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "Happy coding! 🤖" -ForegroundColor Cyan
