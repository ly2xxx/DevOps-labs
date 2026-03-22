#!/bin/bash

# K3s Worker Node Join Script
# For: AI Agent Team Orchestration
# Author: Helpful Bob
# Date: 2026-03-22

set -e  # Exit on error

echo "=================================================="
echo "  K3s Worker Node Join Script"
echo "=================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}ERROR: Please run as root (use sudo)${NC}"
    exit 1
fi

# Parse arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <CONTROL_PLANE_IP> <JOIN_TOKEN> [NODE_NAME]"
    echo ""
    echo "Example:"
    echo "  sudo $0 192.168.1.100 K10abc123::server:xyz789 worker-01"
    echo ""
    exit 1
fi

CONTROL_PLANE_IP=$1
JOIN_TOKEN=$2
NODE_NAME=${3:-worker-$(hostname)}  # Use hostname if name not provided

echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"

# Check OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  ✓ OS: $NAME $VERSION"
else
    echo -e "${RED}  ✗ Cannot detect OS${NC}"
    exit 1
fi

# Check CPU/RAM (more lenient for workers)
CPU_CORES=$(nproc)
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')

echo "  ✓ CPU cores: $CPU_CORES"
echo "  ✓ RAM: ${TOTAL_RAM}GB"

if [ "$TOTAL_RAM" -lt 2 ]; then
    echo -e "${YELLOW}  ⚠ Warning: Less than 2GB RAM. Worker may struggle.${NC}"
fi

echo ""
echo -e "${YELLOW}[2/5] Testing connection to control plane...${NC}"

# Ping test
if ping -c 2 "$CONTROL_PLANE_IP" > /dev/null 2>&1; then
    echo "  ✓ Control plane reachable at $CONTROL_PLANE_IP"
else
    echo -e "  ${RED}✗ Cannot reach control plane at $CONTROL_PLANE_IP${NC}"
    exit 1
fi

# Test K3s port
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$CONTROL_PLANE_IP/6443" 2>/dev/null; then
    echo "  ✓ K3s API port (6443) is accessible"
else
    echo -e "  ${YELLOW}⚠ Warning: Cannot verify K3s port 6443. Firewall issue?${NC}"
fi

echo ""
echo -e "${YELLOW}[3/5] Installing K3s agent...${NC}"

# Install K3s agent
curl -sfL https://get.k3s.io | K3S_URL="https://${CONTROL_PLANE_IP}:6443" \
    K3S_TOKEN="$JOIN_TOKEN" \
    INSTALL_K3S_EXEC="agent --node-name=$NODE_NAME" sh -

if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ K3s agent installed successfully${NC}"
else
    echo -e "  ${RED}✗ K3s agent installation failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[4/5] Waiting for agent to start...${NC}"

# Wait for k3s-agent service
sleep 5

if systemctl is-active --quiet k3s-agent; then
    echo -e "  ${GREEN}✓ k3s-agent service is running${NC}"
else
    echo -e "  ${RED}✗ k3s-agent service failed to start${NC}"
    echo "  Check logs: journalctl -u k3s-agent -xe"
    exit 1
fi

echo ""
echo -e "${YELLOW}[5/5] Verifying node registration...${NC}"

echo "  Node should appear in cluster within 30 seconds"
echo "  Run this on control plane to verify:"
echo ""
echo -e "  ${YELLOW}kubectl get nodes${NC}"
echo ""

# Save node info
mkdir -p /root/k3s-setup
echo "$NODE_NAME" > /root/k3s-setup/node-name.txt
echo "$CONTROL_PLANE_IP" > /root/k3s-setup/control-plane-ip.txt

echo ""
echo -e "${GREEN}=================================================="
echo "  ✓ Worker Node Join Complete!"
echo "==================================================${NC}"
echo ""
echo "Node name: $NODE_NAME"
echo "Control plane: $CONTROL_PLANE_IP"
echo ""
echo "To verify registration, run on control plane:"
echo "  kubectl get nodes"
echo ""
echo "To check this node's status:"
echo "  systemctl status k3s-agent"
echo ""
echo "To view logs:"
echo "  journalctl -u k3s-agent -f"
echo ""
echo "=================================================="
