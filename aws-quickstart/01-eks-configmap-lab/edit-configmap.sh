#!/bin/bash

# Helper script for editing ConfigMaps in EKS
# Usage: ./edit-configmap.sh [configmap-name] [deployment-name]

set -e

CONFIGMAP=${1:-app-config}
DEPLOYMENT=${2:-demo-app}
NAMESPACE="configmap-demo"

echo "=== ConfigMap Editor ==="
echo "ConfigMap: $CONFIGMAP"
echo "Deployment: $DEPLOYMENT"
echo "Namespace: $NAMESPACE"
echo ""

# Check if ConfigMap exists
if ! kubectl get configmap $CONFIGMAP -n $NAMESPACE &>/dev/null; then
  echo "❌ ConfigMap '$CONFIGMAP' not found in namespace '$NAMESPACE'"
  exit 1
fi

# Show current ConfigMap
echo "📋 Current ConfigMap content:"
kubectl get configmap $CONFIGMAP -n $NAMESPACE -o yaml

echo ""
read -p "Press Enter to edit ConfigMap..."

# Edit ConfigMap
kubectl edit configmap $CONFIGMAP -n $NAMESPACE

echo ""
echo "✅ ConfigMap updated!"
echo ""

# Ask if user wants to restart deployment
read -p "Restart deployment '$DEPLOYMENT' to apply changes? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "🔄 Restarting deployment..."
  kubectl rollout restart deployment $DEPLOYMENT -n $NAMESPACE
  
  echo "⏳ Waiting for rollout to complete..."
  kubectl rollout status deployment $DEPLOYMENT -n $NAMESPACE
  
  echo ""
  echo "✅ Deployment restarted successfully!"
  echo ""
  echo "📋 Check pod logs:"
  echo "kubectl logs -l app=$DEPLOYMENT -n $NAMESPACE --tail=50"
else
  echo "⚠️  Deployment NOT restarted. Pods still using old config."
  echo ""
  echo "To restart manually:"
  echo "kubectl rollout restart deployment $DEPLOYMENT -n $NAMESPACE"
fi

echo ""
echo "=== Done! ==="
