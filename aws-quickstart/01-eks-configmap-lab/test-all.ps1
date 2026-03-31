# Quick test script for the ConfigMap lab (PowerShell version)
# This script deploys everything and shows you the results

$ErrorActionPreference = "Stop"
$NAMESPACE = "configmap-demo"

Write-Host "=== EKS ConfigMap Lab - Quick Test ===" -ForegroundColor Cyan
Write-Host ""

# Check kubectl connection
Write-Host "📡 Checking EKS connection..." -ForegroundColor Yellow
try {
    kubectl cluster-info | Out-Null
    Write-Host "✅ Connected to cluster" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl not connected to EKS cluster" -ForegroundColor Red
    Write-Host "Run: aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region YOUR_REGION"
    exit 1
}
Write-Host ""

# Create namespace
Write-Host "📁 Creating namespace..." -ForegroundColor Yellow
kubectl apply -f 00-namespace.yaml

# Set context
kubectl config set-context --current --namespace=$NAMESPACE | Out-Null
Write-Host "✅ Using namespace: $NAMESPACE" -ForegroundColor Green
Write-Host ""

# Deploy ConfigMaps
Write-Host "📝 Creating ConfigMaps..." -ForegroundColor Yellow
kubectl apply -f 01-configmap-env.yaml
kubectl apply -f 02-configmap-volume.yaml
Write-Host "✅ ConfigMaps created" -ForegroundColor Green
Write-Host ""

# Deploy applications
Write-Host "🚀 Deploying applications..." -ForegroundColor Yellow
kubectl apply -f 03-deployment-env.yaml
kubectl apply -f 04-deployment-volume.yaml
Write-Host "✅ Deployments created" -ForegroundColor Green
Write-Host ""

# Wait for pods
Write-Host "⏳ Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=demo-app --timeout=60s
kubectl wait --for=condition=ready pod -l app=demo-app-volume --timeout=60s
Write-Host "✅ Pods are ready" -ForegroundColor Green
Write-Host ""

# Show status
Write-Host "📊 Current status:" -ForegroundColor Cyan
kubectl get all
Write-Host ""

# Show ConfigMap content
Write-Host "📋 ConfigMap (env):" -ForegroundColor Cyan
kubectl get configmap app-config -o yaml
Write-Host ""

# Show pod logs
Write-Host "📜 Logs from demo-app (env vars):" -ForegroundColor Cyan
$POD_ENV = kubectl get pods -l app=demo-app -o jsonpath='{.items[0].metadata.name}'
kubectl logs $POD_ENV | Select-Object -First 20
Write-Host ""

Write-Host "📜 Logs from demo-app-volume (files):" -ForegroundColor Cyan
$POD_VOL = kubectl get pods -l app=demo-app-volume -o jsonpath='{.items[0].metadata.name}'
kubectl logs $POD_VOL | Select-Object -First 20
Write-Host ""

# Instructions for next steps
Write-Host "=== Lab Ready! ===" -ForegroundColor Green
Write-Host ""
Write-Host "✅ All resources deployed successfully" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit ConfigMap: kubectl edit configmap app-config"
Write-Host "2. Restart deployment: kubectl rollout restart deployment demo-app"
Write-Host "3. Check new logs: kubectl logs -l app=demo-app --tail=20"
Write-Host ""
Write-Host "📜 Test volume auto-update:" -ForegroundColor Cyan
Write-Host "1. Edit: kubectl patch configmap app-config-volume -p '{`"data`":{`"log_level`":`"debug`"}}'"
Write-Host "2. Wait 60 seconds: Start-Sleep -Seconds 60"
Write-Host "3. Check: kubectl exec $POD_VOL -- cat /etc/config/log_level"
Write-Host ""
Write-Host "🧹 Cleanup: kubectl delete namespace $NAMESPACE" -ForegroundColor Yellow
