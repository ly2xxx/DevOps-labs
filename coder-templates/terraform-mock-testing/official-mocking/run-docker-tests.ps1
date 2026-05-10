$ErrorActionPreference = "Stop"

Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t terraform-tester .

Write-Host "`nRunning Terraform tests in Docker..." -ForegroundColor Cyan
# Mount the current directory to /workspace in the container and run
docker run --rm -v "${PWD}:/workspace" terraform-tester
