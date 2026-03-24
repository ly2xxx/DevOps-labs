# Build All UBI9-Minimal Coder Template Variants
# Builds four optimized versions for comparison

Write-Host "🐳 Building UBI9-Minimal Coder Templates" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# Build 1: Basic (Python only)
Write-Host "📦 Building BASIC version (Python only)..." -ForegroundColor Yellow
docker build -t coder-template:ubi9-basic -f Dockerfile .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Basic build complete" -ForegroundColor Green
} else {
    Write-Host "❌ Basic build failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Build 2: Optimized (Python only, multi-stage)
Write-Host "📦 Building OPTIMIZED version (Python multi-stage)..." -ForegroundColor Yellow
docker build -t coder-template:ubi9-optimized -f Dockerfile.optimized .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Optimized build complete" -ForegroundColor Green
} else {
    Write-Host "❌ Optimized build failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Build 3: Claude Code (Node.js + npm)
Write-Host "📦 Building CLAUDE CODE version (Node.js)..." -ForegroundColor Yellow
docker build -t coder-template:ubi9-claude -f Dockerfile.with-claude-code .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Claude Code build complete" -ForegroundColor Green
} else {
    Write-Host "❌ Claude Code build failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Build 4: Complete (Node.js + Python)
Write-Host "📦 Building COMPLETE version (Claude Code + Python MCP)..." -ForegroundColor Yellow
docker build -t coder-template:ubi9-complete -f Dockerfile.with-both .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Complete build successful" -ForegroundColor Green
} else {
    Write-Host "❌ Complete build failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "✅ All builds completed successfully!" -ForegroundColor Green
Write-Host "⏱️  Total time: $([math]::Round($duration, 1)) seconds" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Run .\compare-images.ps1 to see size comparison" -ForegroundColor Cyan
