$ErrorActionPreference = "Stop"

# Check if the image already exists
if (-not (docker images -q terraform-tester)) {
    Write-Host "Image 'terraform-tester' not found. Building..." -ForegroundColor Cyan
    docker build -t terraform-tester .
} else {
    Write-Host "Image 'terraform-tester' exists. Skipping build." -ForegroundColor Green
    Write-Host "(Run 'docker rmi terraform-tester' if you need to force a rebuild of the providers)" -ForegroundColor Gray
}

Write-Host "`nRunning Terraform tests in Docker..." -ForegroundColor Cyan
# Mount the current directory to /workspace in the container and run
docker run --rm -v "${PWD}:/workspace" terraform-tester
