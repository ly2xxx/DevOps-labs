#!/bin/bash

# K3s Control Plane Setup Script
# For: AI Agent Team Orchestration
# Author: Helpful Bob
# Date: 2026-03-22

set -e  # Exit on error

echo "=================================================="
echo "  K3s Control Plane Setup for AI Agent Team"
echo "=================================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}ERROR: Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

# Check OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  ✓ OS: $NAME $VERSION"
else
    echo -e "${RED}  ✗ Cannot detect OS${NC}"
    exit 1
fi

# Check CPU cores
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -lt 2 ]; then
    echo -e "${YELLOW}  ⚠ Warning: Only $CPU_CORES CPU core(s). Recommended: 2+${NC}"
else
    echo "  ✓ CPU cores: $CPU_CORES"
fi

# Check RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 4 ]; then
    echo -e "${YELLOW}  ⚠ Warning: Only ${TOTAL_RAM}GB RAM. Recommended: 4GB+${NC}"
else
    echo "  ✓ RAM: ${TOTAL_RAM}GB"
fi

# Check disk space
DISK_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$DISK_SPACE" -lt 20 ]; then
    echo -e "${YELLOW}  ⚠ Warning: Only ${DISK_SPACE}GB free. Recommended: 20GB+${NC}"
else
    echo "  ✓ Disk space: ${DISK_SPACE}GB free"
fi

echo ""
echo -e "${YELLOW}[2/6] Installing K3s control plane...${NC}"

# Install K3s with custom configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --write-kubeconfig-mode=644 \
    --disable=traefik \
    --node-name=agent-control-plane \
    --cluster-cidr=10.42.0.0/16 \
    --service-cidr=10.43.0.0/16" sh -

if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ K3s installed successfully${NC}"
else
    echo -e "  ${RED}✗ K3s installation failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[3/6] Waiting for K3s to be ready...${NC}"

# Wait for K3s to start
sleep 10

# Check if kubectl works
if ! command -v kubectl &> /dev/null; then
    # Link k3s kubectl
    ln -s /usr/local/bin/k3s /usr/local/bin/kubectl
fi

# Wait for node to be ready
echo "  Waiting for node to be ready..."
timeout 120 bash -c 'until kubectl get nodes | grep -q "Ready"; do sleep 2; done' || {
    echo -e "  ${RED}✗ Timeout waiting for node${NC}"
    exit 1
}

echo -e "  ${GREEN}✓ Node is ready${NC}"

echo ""
echo -e "${YELLOW}[4/6] Extracting join token for worker nodes...${NC}"

# Get the node token
NODE_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
CONTROL_PLANE_IP=$(hostname -I | awk '{print $1}')

# Save token and IP for later
mkdir -p /root/k3s-setup
echo "$NODE_TOKEN" > /root/k3s-setup/node-token.txt
echo "$CONTROL_PLANE_IP" > /root/k3s-setup/control-plane-ip.txt

echo "  ✓ Join token saved to: /root/k3s-setup/node-token.txt"
echo "  ✓ Control plane IP: $CONTROL_PLANE_IP"

echo ""
echo -e "${YELLOW}[5/6] Installing kubectl completion...${NC}"

# Add kubectl completion to bashrc
if ! grep -q "kubectl completion bash" /root/.bashrc; then
    echo "source <(kubectl completion bash)" >> /root/.bashrc
    echo "alias k=kubectl" >> /root/.bashrc
    echo "complete -F __start_kubectl k" >> /root/.bashrc
    echo "  ✓ Added kubectl completion and alias 'k'"
else
    echo "  ✓ kubectl completion already configured"
fi

echo ""
echo -e "${YELLOW}[6/6] Verifying installation...${NC}"

# Check cluster status
kubectl cluster-info
echo ""
kubectl get nodes -o wide

echo ""
echo -e "${GREEN}=================================================="
echo "  ✓ K3s Control Plane Setup Complete!"
echo "==================================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Join worker nodes using this command on each worker:"
echo ""
echo -e "${YELLOW}   curl -sfL https://get.k3s.io | K3S_URL=https://${CONTROL_PLANE_IP}:6443 \\"
echo "     K3S_TOKEN=${NODE_TOKEN} sh -${NC}"
echo ""
echo "2. Or copy the join script to workers and run:"
echo ""
echo "   ./join-worker.sh $CONTROL_PLANE_IP $NODE_TOKEN"
echo ""
echo "3. Verify nodes:"
echo ""
echo "   kubectl get nodes"
echo ""
echo "4. Access kubeconfig from other machines:"
echo ""
echo "   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
echo ""
echo "=================================================="
echo ""
echo "Token and IP saved in /root/k3s-setup/ for reference"
echo ""
