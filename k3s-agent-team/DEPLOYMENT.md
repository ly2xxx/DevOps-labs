# K3s AI Agent Team - Deployment Guide

Complete step-by-step deployment guide for the K3s AI agent orchestration system.

## Prerequisites Checklist

- [ ] 2-3 old PCs/laptops running Linux (Ubuntu 20.04+ recommended)
- [ ] Network connectivity between all machines
- [ ] Root/sudo access on all machines
- [ ] At least one machine with:
  - 2+ CPU cores
  - 4GB+ RAM
  - 20GB+ free disk space

---

## Deployment Steps

### Step 1: Set Up K3s Cluster

#### On Primary Node (Control Plane)

```bash
# 1. Copy setup script to the primary node
scp scripts/setup-control-plane.sh user@primary-node:/tmp/

# 2. SSH into primary node
ssh user@primary-node

# 3. Run control plane setup
cd /tmp
chmod +x setup-control-plane.sh
sudo ./setup-control-plane.sh

# 4. Note the output - you'll need:
#    - Control plane IP (e.g., 192.168.1.100)
#    - Join token (saved in /root/k3s-setup/node-token.txt)
```

**Expected Output:**
```
================================================
  ✓ K3s Control Plane Setup Complete!
==================================================

Next steps:

1. Join worker nodes using this command on each worker:

   curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.100:6443 \
     K3S_TOKEN=K10abc123::server:xyz789 sh -

...
```

---

#### On Worker Nodes

```bash
# 1. Copy join script to each worker
scp scripts/join-worker.sh user@worker-01:/tmp/
scp scripts/join-worker.sh user@worker-02:/tmp/

# 2. SSH into first worker
ssh user@worker-01

# 3. Run join script (use values from control plane setup)
cd /tmp
chmod +x join-worker.sh
sudo ./join-worker.sh 192.168.1.100 K10abc123::server:xyz789 worker-01

# 4. Repeat for other workers
```

---

#### Verify Cluster

```bash
# On control plane node
kubectl get nodes

# Expected output:
# NAME                  STATUS   ROLES                  AGE
# agent-control-plane   Ready    control-plane,master   5m
# worker-01             Ready    <none>                 2m
# worker-02             Ready    <none>                 1m
```

---

### Step 2: Deploy Agent Infrastructure

#### On Control Plane

```bash
# 1. Copy k8s manifests to control plane
scp -r k8s/ user@primary-node:/tmp/k3s-agent-team/

# 2. SSH to control plane
ssh user@primary-node

# 3. Deploy namespaces
kubectl apply -f /tmp/k3s-agent-team/k8s/namespaces/

# Verify
kubectl get namespaces | grep agents

# Expected:
# marketing-agents   Active   10s
# dev-agents         Active   10s
# test-agents        Active   10s
# coordinator        Active   10s

# 4. Deploy storage
kubectl apply -f /tmp/k3s-agent-team/k8s/storage/

# 5. Deploy resource quotas
kubectl apply -f /tmp/k3s-agent-team/k8s/quotas/

# 6. Deploy network policies
kubectl apply -f /tmp/k3s-agent-team/k8s/network-policies/

# 7. Deploy agent deployments
kubectl apply -f /tmp/k3s-agent-team/k8s/deployments/
```

---

### Step 3: Build & Deploy OpenClaw Agent Images

**Note:** You need to create Docker images for each agent role. This is a placeholder workflow.

```bash
# On control plane (or build machine with Docker)

# 1. Create Dockerfiles for each role
# See docker/ folder for templates (to be created separately)

# 2. Build images
docker build -f docker/Dockerfile.marketing -t openclaw-marketing:latest .
docker build -f docker/Dockerfile.developer -t openclaw-developer:latest .
docker build -f docker/Dockerfile.tester -t openclaw-tester:latest .

# 3. Load into K3s
# Option A: Direct import
docker save openclaw-marketing:latest | sudo k3s ctr images import -

# Option B: Use local registry (recommended for multi-node)
# Set up local registry first:
docker run -d -p 5000:5000 --name registry registry:2
docker tag openclaw-marketing:latest localhost:5000/openclaw-marketing:latest
docker push localhost:5000/openclaw-marketing:latest

# Update deployment YAMLs to use localhost:5000/openclaw-marketing:latest
```

---

### Step 4: Deploy Orchestration Controller

```bash
# On control plane

# 1. Copy controller files
scp -r controller/ user@primary-node:/tmp/k3s-agent-team/

# 2. SSH to control plane
ssh user@primary-node

# 3. Build controller image
cd /tmp/k3s-agent-team/controller
docker build -t agent-controller:latest .

# 4. Load into K3s
docker save agent-controller:latest | sudo k3s ctr images import -

# 5. Deploy controller
kubectl apply -f controller-deployment.yaml

# 6. Verify
kubectl get pods -n coordinator

# Expected:
# NAME                               READY   STATUS    RESTARTS   AGE
# agent-controller-abc123-xyz        1/1     Running   0          30s
```

---

### Step 5: Verify Full Stack

```bash
# On control plane

# 1. Run verification script
./scripts/verify-cluster.sh

# 2. Check all namespaces
kubectl get all --all-namespaces | grep agent

# 3. Check controller logs
kubectl logs -n coordinator -l app=agent-controller

# 4. Port-forward controller for testing
kubectl port-forward -n coordinator svc/agent-controller 8080:8080
```

---

### Step 6: Test Orchestration

```bash
# On control plane or any machine that can reach the controller

# 1. Health check
curl http://localhost:8080/health

# 2. Get status
curl http://localhost:8080/status

# 3. Submit a test task
curl -X POST http://localhost:8080/task \
  -H "Content-Type: application/json" \
  -d '{
    "role": "MARKETING",
    "task": "Test deployment",
    "replicas": 1
  }'

# 4. Check if agent pod started
kubectl get pods -n marketing-agents

# Expected:
# NAME                              READY   STATUS    RESTARTS   AGE
# marketing-agent-abc123-xyz        1/1     Running   0          15s

# 5. Check pod logs
kubectl logs -n marketing-agents -l role=marketing

# 6. Scale back down
TASK_ID="marketing-1711097400"  # Use actual task ID from step 3
curl -X POST http://localhost:8080/task/$TASK_ID/complete

# 7. Verify scale-down
kubectl get pods -n marketing-agents

# Should show no pods or terminating pods
```

---

## Troubleshooting

### Issue: Worker can't join cluster

**Symptoms:**
- `join-worker.sh` fails with connection error

**Solutions:**
```bash
# On control plane, check firewall
sudo ufw status
sudo ufw allow 6443/tcp

# Test connectivity from worker
telnet <CONTROL_PLANE_IP> 6443

# Check K3s service on control plane
sudo systemctl status k3s
```

---

### Issue: Pods stuck in Pending

**Symptoms:**
- Agent pods show "Pending" status

**Solutions:**
```bash
# Check pod events
kubectl describe pod <POD_NAME> -n <NAMESPACE>

# Common causes:
# 1. Image pull failure (image doesn't exist)
# 2. Resource constraints (not enough CPU/memory)
# 3. PVC not bound

# Check PVCs
kubectl get pvc -n coordinator

# Check resource usage
kubectl top nodes
```

---

### Issue: Controller can't scale deployments

**Symptoms:**
- `/task` endpoint returns "Failed to scale deployment"

**Solutions:**
```bash
# Check controller logs
kubectl logs -n coordinator -l app=agent-controller

# Verify RBAC permissions
kubectl auth can-i patch deployments \
  --as=system:serviceaccount:coordinator:agent-controller \
  -n marketing-agents

# Check ClusterRole
kubectl describe clusterrole agent-controller-role

# Check ClusterRoleBinding
kubectl describe clusterrolebinding agent-controller-binding
```

---

## Post-Deployment Configuration

### 1. Set Up External Access (Optional)

```bash
# Option A: NodePort service
kubectl patch svc agent-controller -n coordinator \
  -p '{"spec":{"type":"NodePort"}}'

# Get the port
kubectl get svc agent-controller -n coordinator

# Access via: http://<NODE_IP>:<NODE_PORT>

# Option B: Ingress (requires ingress controller)
# Uncomment ingress section in controller-deployment.yaml
# and configure your DNS/hosts file
```

### 2. Configure Persistent Logging

```bash
# Forward logs to a file
kubectl logs -n coordinator -l app=agent-controller -f > /var/log/agent-controller.log &

# Or set up Loki/Promtail for centralized logging
```

### 3. Set Up Monitoring (Optional)

```bash
# Install Prometheus + Grafana
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/setup/*.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/*.yaml

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Default login: admin/admin
```

---

## Maintenance

### Update Agent Images

```bash
# Build new version
docker build -t openclaw-marketing:v2 .

# Import to K3s
docker save openclaw-marketing:v2 | sudo k3s ctr images import -

# Update deployment
kubectl set image deployment/marketing-agent \
  openclaw-marketing=openclaw-marketing:v2 \
  -n marketing-agents
```

### Backup Configuration

```bash
# Backup all manifests
kubectl get all --all-namespaces -o yaml > backup-$(date +%Y%m%d).yaml

# Backup PVCs
kubectl get pvc --all-namespaces -o yaml > pvc-backup-$(date +%Y%m%d).yaml
```

### Uninstall

```bash
# Delete all agent resources
kubectl delete namespace marketing-agents dev-agents test-agents coordinator

# Uninstall K3s from control plane
sudo /usr/local/bin/k3s-uninstall.sh

# Uninstall K3s from workers
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

---

## Success Criteria

You've successfully deployed the system when:

- [✓] All nodes show "Ready" status
- [✓] All namespaces exist
- [✓] Controller pod is running
- [✓] `/health` endpoint returns 200
- [✓] Can submit a task via `/task` endpoint
- [✓] Agent pods scale up when task submitted
- [✓] Agent pods scale down when task completed
- [✓] Network policies isolate namespaces
- [✓] Resource quotas are enforced

---

## Next Steps

Once deployed:

1. Integrate with OpenClaw agents (configure agent images)
2. Set up task queue for production workloads
3. Add authentication to controller API
4. Configure monitoring dashboards
5. Document your specific agent workflows
6. Set up automated backups

Good luck! 🚀
