# K3s Cluster Setup Scripts

These scripts automate the setup of a multi-node K3s cluster for AI agent orchestration.

## Scripts Overview

| Script | Purpose | Run On |
|--------|---------|--------|
| `setup-control-plane.sh` | Install K3s control plane | Primary node |
| `join-worker.sh` | Join worker to cluster | Worker nodes |
| `verify-cluster.sh` | Health check cluster | Control plane |

## Installation Steps

### 1. Setup Control Plane (Primary Node)

**Prerequisites:**
- Linux (Ubuntu 20.04+, Debian, RHEL, etc.)
- 2+ CPU cores
- 4GB+ RAM
- 20GB+ free disk space
- Root/sudo access

**Run:**
```bash
# Make executable
chmod +x setup-control-plane.sh

# Run as root
sudo ./setup-control-plane.sh
```

**What it does:**
- ✅ Checks system prerequisites
- ✅ Installs K3s as control plane
- ✅ Configures kubeconfig
- ✅ Extracts join token
- ✅ Sets up kubectl completion
- ✅ Displays worker join command

**Output:**
- Join token saved in `/root/k3s-setup/node-token.txt`
- Control plane IP in `/root/k3s-setup/control-plane-ip.txt`

---

### 2. Join Worker Nodes

**Prerequisites:**
- Linux system
- 1+ CPU core
- 2GB+ RAM
- Network access to control plane (port 6443)
- Root/sudo access

**Run:**
```bash
# Make executable
chmod +x join-worker.sh

# Run with parameters from control plane setup
sudo ./join-worker.sh <CONTROL_PLANE_IP> <JOIN_TOKEN> [WORKER_NAME]
```

**Example:**
```bash
sudo ./join-worker.sh 192.168.1.100 K10abc123::server:xyz789 worker-01
```

**What it does:**
- ✅ Checks prerequisites
- ✅ Tests connectivity to control plane
- ✅ Installs K3s agent
- ✅ Registers with cluster
- ✅ Starts k3s-agent service

**Verify on control plane:**
```bash
kubectl get nodes
```

---

### 3. Verify Cluster Health

**Run on control plane:**
```bash
# Make executable
chmod +x verify-cluster.sh

# Run (no sudo needed if kubeconfig accessible)
./verify-cluster.sh
```

**What it checks:**
- ✅ Cluster info
- ✅ Node status
- ✅ System pod health
- ✅ Resource usage
- ✅ Storage classes
- ✅ Namespaces
- ✅ K3s service status

---

## Multi-Node Setup Example

**3-node cluster (1 control plane + 2 workers):**

```bash
# On node-01 (control plane)
sudo ./setup-control-plane.sh

# Note the output:
#   Control plane IP: 192.168.1.100
#   Join token: K10abc123::server:xyz789

# On node-02 (worker)
sudo ./join-worker.sh 192.168.1.100 K10abc123::server:xyz789 worker-01

# On node-03 (worker)
sudo ./join-worker.sh 192.168.1.100 K10abc123::server:xyz789 worker-02

# Back on node-01, verify:
./verify-cluster.sh

# Expected output:
#   NAME                  STATUS   ROLES                  AGE
#   agent-control-plane   Ready    control-plane,master   5m
#   worker-01             Ready    <none>                 2m
#   worker-02             Ready    <none>                 1m
```

---

## Troubleshooting

### Control Plane Issues

**Problem:** K3s fails to start
```bash
# Check service status
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -xe

# Common fixes:
# - Check firewall (allow port 6443)
# - Ensure no conflicting Docker/Podman
# - Check disk space
```

**Problem:** kubectl commands fail
```bash
# Check kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
ls -la /etc/rancher/k3s/k3s.yaml

# Ensure readable (script sets mode 644)
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

---

### Worker Node Issues

**Problem:** Worker can't reach control plane
```bash
# Test connectivity
ping <CONTROL_PLANE_IP>
telnet <CONTROL_PLANE_IP> 6443

# Check firewall on control plane
sudo ufw allow 6443/tcp  # If using UFW
sudo firewall-cmd --add-port=6443/tcp --permanent  # If using firewalld
sudo firewall-cmd --reload
```

**Problem:** Worker joins but shows NotReady
```bash
# On worker, check agent logs
sudo journalctl -u k3s-agent -f

# Check network plugin
kubectl get pods -n kube-system | grep flannel

# On control plane, describe the node
kubectl describe node <worker-name>
```

**Problem:** Wrong join token
```bash
# On control plane, get the correct token
sudo cat /var/lib/rancher/k3s/server/node-token

# Re-run join on worker
sudo /usr/local/bin/k3s-agent-uninstall.sh  # Uninstall first
sudo ./join-worker.sh <IP> <CORRECT_TOKEN> <NAME>
```

---

## Uninstallation

### Remove K3s from control plane:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

### Remove K3s from worker:
```bash
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

---

## Next Steps

Once cluster is running:

1. **Deploy agent infrastructure:**
   ```bash
   kubectl apply -f ../k8s/namespaces/
   kubectl apply -f ../k8s/deployments/
   ```

2. **Set up network policies:**
   ```bash
   kubectl apply -f ../k8s/network-policies/
   ```

3. **Configure resource quotas:**
   ```bash
   kubectl apply -f ../k8s/quotas/
   ```

4. **Deploy orchestration controller:**
   ```bash
   kubectl apply -f ../controller/controller-deployment.yaml
   ```

---

## Notes

- **Security:** This setup uses K3s defaults. For production:
  - Change default kubeconfig permissions
  - Rotate join tokens regularly
  - Enable RBAC policies
  - Use network policies from day one

- **Storage:** K3s includes local-path provisioner by default
  - Good for development
  - For production, consider Longhorn, Rook/Ceph, or NFS

- **Traefik:** Disabled in setup (not needed for internal agents)
  - Re-enable if you need ingress: remove `--disable=traefik`

- **Firewall ports:**
  - 6443: Kubernetes API (required)
  - 8472: Flannel VXLAN (if using multi-node)
  - 10250: Kubelet metrics (optional)
