#!/bin/bash

# K3s Cluster Verification Script
# For: AI Agent Team Orchestration
# Author: Helpful Bob
# Date: 2026-03-22

set -e

echo "=================================================="
echo "  K3s Cluster Health Check"
echo "=================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}ERROR: kubectl not found${NC}"
    echo "  Run this script on the control plane node"
    exit 1
fi

echo -e "${BLUE}[1/7] Cluster Info${NC}"
echo "─────────────────────────────────────────────────"
kubectl cluster-info
echo ""

echo -e "${BLUE}[2/7] Node Status${NC}"
echo "─────────────────────────────────────────────────"
kubectl get nodes -o wide
echo ""

# Check node readiness
NOT_READY=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l)
if [ "$NOT_READY" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Warning: $NOT_READY node(s) not ready${NC}"
else
    echo -e "${GREEN}✓ All nodes ready${NC}"
fi
echo ""

echo -e "${BLUE}[3/7] System Pods${NC}"
echo "─────────────────────────────────────────────────"
kubectl get pods -n kube-system
echo ""

# Check for failing pods
FAILING_PODS=$(kubectl get pods -n kube-system --no-headers | grep -v "Running\|Completed" | wc -l)
if [ "$FAILING_PODS" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Warning: $FAILING_PODS pod(s) not running${NC}"
else
    echo -e "${GREEN}✓ All system pods healthy${NC}"
fi
echo ""

echo -e "${BLUE}[4/7] Resource Usage${NC}"
echo "─────────────────────────────────────────────────"
kubectl top nodes 2>/dev/null || echo "  (Metrics server not installed - CPU/memory metrics unavailable)"
echo ""

echo -e "${BLUE}[5/7] Storage Classes${NC}"
echo "─────────────────────────────────────────────────"
kubectl get storageclass
echo ""

echo -e "${BLUE}[6/7] Namespaces${NC}"
echo "─────────────────────────────────────────────────"
kubectl get namespaces
echo ""

echo -e "${BLUE}[7/7] Cluster Component Status${NC}"
echo "─────────────────────────────────────────────────"

# Check K3s specific components
if [ -f /var/lib/rancher/k3s/server/node-token ]; then
    echo "  ✓ Control plane node detected"
    echo "  Join token location: /var/lib/rancher/k3s/server/node-token"
    
    # Check services
    if systemctl is-active --quiet k3s; then
        echo -e "  ${GREEN}✓ k3s service running${NC}"
    else
        echo -e "  ${RED}✗ k3s service not running${NC}"
    fi
else
    # Worker node
    if systemctl is-active --quiet k3s-agent; then
        echo -e "  ${GREEN}✓ k3s-agent service running${NC}"
    else
        echo -e "  ${RED}✗ k3s-agent service not running${NC}"
    fi
fi

echo ""
echo "─────────────────────────────────────────────────"

# Summary
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
READY_NODES=$(kubectl get nodes --no-headers | grep "Ready" | wc -l)

echo ""
echo -e "${GREEN}Cluster Summary:${NC}"
echo "  Nodes: $READY_NODES/$TOTAL_NODES ready"

# Check if agent namespaces exist
AGENT_NAMESPACES=$(kubectl get namespaces --no-headers | grep -E "marketing-agents|dev-agents|test-agents|coordinator" | wc -l)
if [ "$AGENT_NAMESPACES" -gt 0 ]; then
    echo "  Agent namespaces: $AGENT_NAMESPACES deployed"
else
    echo "  Agent namespaces: Not yet deployed"
    echo ""
    echo -e "${YELLOW}To deploy agent infrastructure:${NC}"
    echo "  kubectl apply -f ../k8s/namespaces/"
fi

echo ""
echo "=================================================="
echo ""
echo "For more details:"
echo "  kubectl describe nodes"
echo "  kubectl get all --all-namespaces"
echo "  journalctl -u k3s -f           # Control plane logs"
echo "  journalctl -u k3s-agent -f     # Worker logs"
echo ""
