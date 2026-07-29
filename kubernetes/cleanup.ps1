# Cleanup script for Kubernetes lab resources
Set-Location $PSScriptRoot

Write-Host "🧹 Deleting Kubernetes resources in default namespace..." -ForegroundColor Yellow

$files = @(
    "deployment.yaml",
    "service_nodeport.yaml",
    "service.yaml",
    "ingress.yaml",
    "ingress-docs.yaml",
    "secret.yaml",
    "configmap.yaml",
    "curlpod.yaml"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Deleting $file..." -ForegroundColor Cyan
        kubectl delete -f $file --ignore-not-found=true
    }
}

Write-Host "`n🧹 Deleting prod namespace and all its resources..." -ForegroundColor Yellow
if (Test-Path "namespace.yaml") {
    kubectl delete -f namespace.yaml --ignore-not-found=true
}

Write-Host "`n✅ All Kubernetes lab resources successfully cleaned up!" -ForegroundColor Green
