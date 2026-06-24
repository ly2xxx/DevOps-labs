# K3s & Kubernetes Cheat Sheet

Quick reference for K3s installation, kubectl cluster management, and custom API controller operations.

---

## 🚀 K3s Cluster Setup & Join

```bash
# Setup control plane (master node)
sudo ./scripts/setup-control-plane.sh

# Join a worker node
sudo ./scripts/join-worker.sh <CONTROL_PLANE_IP> <JOIN_TOKEN> <NODE_NAME>

# Verify cluster status
./scripts/verify-cluster.sh
```

---

## ⛵ Kubectl Cluster Management

### Inspecting Nodes & Cluster
```bash
# List all nodes
kubectl get nodes

# View resources utilization on nodes
kubectl top nodes

# Detailed node status
kubectl describe node <NODE_NAME>
```

### Pod & Service Inspection
```bash
# List pods in a specific namespace
kubectl get pods -n dev-agents
kubectl get pods -n marketing-agents
kubectl get pods -n coordinator

# List pods across all namespaces
kubectl get pods --all-namespaces

# Get live status updates (watch mode)
kubectl get pods -w -n dev-agents

# Describe a specific pod (useful for troubleshooting pending/crashing pods)
kubectl describe pod <POD_NAME> -n <NAMESPACE>
```

### Viewing Logs
```bash
# Tail logs from the agent controller
kubectl logs -n coordinator -l app=agent-controller -f

# Tail logs from a specific pod
kubectl logs -n dev-agents <POD_NAME> -f

# View previous container logs (after crash)
kubectl logs <POD_NAME> -n <NAMESPACE> --previous
```

### Network Policies & Quotas
```bash
# Get resource quotas in a namespace
kubectl describe quota -n marketing-agents

# View network policies
kubectl get networkpolicy -n dev-agents
kubectl describe networkpolicy dev-isolation -n dev-agents
```

### Scale Workloads Manually
```bash
# Scale deployment replicas
kubectl scale deployment marketing-agent -n marketing-agents --replicas=3
```

---

## 🤖 Custom API Controller Operations

The AI Agent Controller runs an HTTP API on port 8080. If running inside Kubernetes, port-forward first:
```bash
kubectl port-forward -n coordinator svc/agent-controller 8080:8080
```

### Submit a Task
```bash
curl -X POST http://localhost:8080/task \
  -H "Content-Type: application/json" \
  -d '{"role": "MARKETING", "task": "Analyze campaign data", "replicas": 2}'
```

### Check Cluster Task Status
```bash
curl http://localhost:8080/status | jq
```

### Manually Scale Roles via Controller API
```bash
curl -X POST http://localhost:8080/scale \
  -H "Content-Type: application/json" \
  -d '{"role": "DEVELOPER", "replicas": 3}'
```

### Complete a Task
```bash
curl -X POST http://localhost:8080/task/<TASK_ID>/complete
```

---

## 🔍 Troubleshooting Commands

```bash
# Check RBAC capabilities for the controller service account
kubectl auth can-i patch deployments \
  --as=system:serviceaccount:coordinator:agent-controller -n dev-agents

# Run a temporary debug pod inside the cluster (netshoot has network debug tools)
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- /bin/bash

# Force delete a stuck pod
kubectl delete pod <POD_NAME> -n <NAMESPACE> --force --grace-period=0

# Check cluster events sorted by time
kubectl get events --sort-by='.lastTimestamp'
```
