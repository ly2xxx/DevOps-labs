#!/bin/bash

# Quick test script for the ConfigMap lab
# This script deploys everything and shows you the results

set -e

NAMESPACE="configmap-demo"

echo "=== EKS ConfigMap Lab - Quick Test ==="
echo ""

# Check kubectl connection
echo "📡 Checking EKS connection..."
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ kubectl not connected to EKS cluster"
  echo "Run: aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region YOUR_REGION"
  exit 1
fi

echo "✅ Connected to cluster"
echo ""

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f 00-namespace.yaml

# Set context
kubectl config set-context --current --namespace=$NAMESPACE
echo "✅ Using namespace: $NAMESPACE"
echo ""

# Deploy ConfigMaps
echo "📝 Creating ConfigMaps..."
kubectl apply -f 01-configmap-env.yaml
kubectl apply -f 02-configmap-volume.yaml
echo "✅ ConfigMaps created"
echo ""

# Deploy applications
echo "🚀 Deploying applications..."
kubectl apply -f 03-deployment-env.yaml
kubectl apply -f 04-deployment-volume.yaml
echo "✅ Deployments created"
echo ""

# Wait for pods
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=demo-app --timeout=60s
kubectl wait --for=condition=ready pod -l app=demo-app-volume --timeout=60s
echo "✅ Pods are ready"
echo ""

# Show status
echo "📊 Current status:"
kubectl get all
echo ""

# Show ConfigMap content
echo "📋 ConfigMap (env):"
kubectl get configmap app-config -o yaml | grep -A 20 "^data:"
echo ""

# Show pod logs
echo "📜 Logs from demo-app (env vars):"
POD_ENV=$(kubectl get pods -l app=demo-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_ENV | head -n 20
echo ""

echo "📜 Logs from demo-app-volume (files):"
POD_VOL=$(kubectl get pods -l app=demo-app-volume -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_VOL | head -n 20
echo ""

# Instructions for next steps
echo "=== Lab Ready! ==="
echo ""
echo "✅ All resources deployed successfully"
echo ""
echo "📚 Next steps:"
echo "1. Edit ConfigMap: kubectl edit configmap app-config"
echo "2. Restart deployment: kubectl rollout restart deployment demo-app"
echo "3. Check new logs: kubectl logs -l app=demo-app --tail=20"
echo ""
echo "📜 Test volume auto-update:"
echo "1. Edit: kubectl patch configmap app-config-volume -p '{\"data\":{\"log_level\":\"debug\"}}'"
echo "2. Wait 60 seconds"
echo "3. Check: kubectl exec $POD_VOL -- cat /etc/config/log_level"
echo ""
echo "🧹 Cleanup: kubectl delete namespace $NAMESPACE"
