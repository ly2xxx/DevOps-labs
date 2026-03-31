#!/bin/bash

# Cleanup script for ConfigMap lab

NAMESPACE="configmap-demo"

echo "=== Cleaning up ConfigMap Lab ==="
echo ""

read -p "Delete namespace '$NAMESPACE' and all resources? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "🧹 Deleting namespace..."
  kubectl delete namespace $NAMESPACE
  
  echo ""
  echo "✅ Cleanup complete!"
  echo ""
  echo "Verify:"
  kubectl get namespace | grep $NAMESPACE || echo "✅ Namespace deleted"
else
  echo "❌ Cleanup cancelled"
  echo ""
  echo "To delete manually:"
  echo "kubectl delete namespace $NAMESPACE"
fi
