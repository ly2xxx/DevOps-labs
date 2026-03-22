# K3s AI Agent Team - Quick Reference

**One-page cheat sheet for common operations**

---

## Initial Setup

```bash
# Control plane
sudo ./scripts/setup-control-plane.sh

# Workers (repeat for each)
sudo ./scripts/join-worker.sh <CONTROL_PLANE_IP> <TOKEN> <NODE_NAME>

# Verify
./scripts/verify-cluster.sh
```

---

## Deploy Infrastructure

```bash
# All at once
kubectl apply -f k8s/namespaces/
kubectl apply -f k8s/storage/
kubectl apply -f k8s/quotas/
kubectl apply -f k8s/network-policies/
kubectl apply -f k8s/deployments/
kubectl apply -f controller/controller-deployment.yaml

# Verify
kubectl get all --all-namespaces | grep agent
```

---

## API Operations

### Port-Forward Controller
```bash
kubectl port-forward -n coordinator svc/agent-controller 8080:8080
```

### Submit Task
```bash
curl -X POST http://localhost:8080/task \
  -H "Content-Type: application/json" \
  -d '{"role": "MARKETING", "task": "Your task", "replicas": 2}'
```

### Check Status
```bash
curl http://localhost:8080/status | jq
```

### Complete Task
```bash
curl -X POST http://localhost:8080/task/<TASK_ID>/complete
```

### Manual Scale
```bash
curl -X POST http://localhost:8080/scale \
  -H "Content-Type: application/json" \
  -d '{"role": "DEVELOPER", "replicas": 3}'
```

---

## Kubernetes Commands

### Check Nodes
```bash
kubectl get nodes
kubectl top nodes
```

### Check Pods
```bash
# All agent pods
kubectl get pods -n marketing-agents
kubectl get pods -n dev-agents
kubectl get pods -n test-agents

# Controller
kubectl get pods -n coordinator
```

### View Logs
```bash
# Controller logs
kubectl logs -n coordinator -l app=agent-controller -f

# Agent logs
kubectl logs -n marketing-agents -l role=marketing -f
```

### Describe Resources
```bash
kubectl describe deployment marketing-agent -n marketing-agents
kubectl describe pod <POD_NAME> -n <NAMESPACE>
```

### Check Quotas
```bash
kubectl describe quota -n marketing-agents
kubectl describe quota -n dev-agents
kubectl describe quota -n test-agents
```

### Check Network Policies
```bash
kubectl get networkpolicy -n marketing-agents
kubectl describe networkpolicy marketing-isolation -n marketing-agents
```

---

## Scaling

### Via API
```bash
# Scale up
curl -X POST http://localhost:8080/scale \
  -d '{"role": "MARKETING", "replicas": 3}'

# Scale down
curl -X POST http://localhost:8080/scale \
  -d '{"role": "MARKETING", "replicas": 0}'
```

### Via kubectl
```bash
# Scale up
kubectl scale deployment marketing-agent -n marketing-agents --replicas=3

# Scale down
kubectl scale deployment marketing-agent -n marketing-agents --replicas=0
```

---

## Troubleshooting

### Controller Not Working
```bash
# Check logs
kubectl logs -n coordinator -l app=agent-controller

# Restart controller
kubectl rollout restart deployment agent-controller -n coordinator

# Check RBAC
kubectl auth can-i patch deployments \
  --as=system:serviceaccount:coordinator:agent-controller -n marketing-agents
```

### Pods Stuck Pending
```bash
# Check events
kubectl describe pod <POD_NAME> -n <NAMESPACE>

# Check resources
kubectl top nodes
kubectl describe node <NODE_NAME>

# Check PVC
kubectl get pvc -n coordinator
```

### Network Issues
```bash
# Test pod connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- /bin/bash

# Inside pod:
nslookup kubernetes.default
curl http://agent-controller.coordinator:8080/health
```

---

## Maintenance

### Update Agent Image
```bash
# Build new image
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
# Export all resources
kubectl get all --all-namespaces -o yaml > backup.yaml

# Export specific namespace
kubectl get all -n marketing-agents -o yaml > marketing-backup.yaml
```

### Delete Everything
```bash
# Delete agent infrastructure (keeps K3s)
kubectl delete namespace marketing-agents dev-agents test-agents coordinator

# Uninstall K3s
sudo /usr/local/bin/k3s-uninstall.sh                # Control plane
sudo /usr/local/bin/k3s-agent-uninstall.sh          # Workers
```

---

## Monitoring Script

Save as `monitor.sh`:

```bash
#!/bin/bash
while true; do
  clear
  echo "=== K3s AI Agent Team Status ==="
  echo ""
  
  echo "--- Nodes ---"
  kubectl get nodes
  
  echo ""
  echo "--- Agent Pods ---"
  kubectl get pods -n marketing-agents -o wide
  kubectl get pods -n dev-agents -o wide
  kubectl get pods -n test-agents -o wide
  
  echo ""
  echo "--- API Status ---"
  curl -s http://localhost:8080/status | jq -r '
    "Active Tasks: \(.active_tasks)",
    "Marketing: \(.agents.MARKETING.replicas) replicas",
    "Developer: \(.agents.DEVELOPER.replicas) replicas",
    "Tester: \(.agents.TESTER.replicas) replicas"
  '
  
  sleep 5
done
```

---

## Common Tasks

### Start a Marketing Campaign Analysis
```bash
curl -X POST http://localhost:8080/task \
  -H "Content-Type: application/json" \
  -d '{
    "role": "MARKETING",
    "task": "Analyze Q1 campaign performance",
    "replicas": 2
  }' | tee task.json

TASK_ID=$(jq -r '.task_id' task.json)
echo "Task ID: $TASK_ID"

# Wait for completion, then:
curl -X POST http://localhost:8080/task/$TASK_ID/complete
```

### Emergency Scale-Up All Roles
```bash
for ROLE in MARKETING DEVELOPER TESTER; do
  curl -X POST http://localhost:8080/scale \
    -H "Content-Type: application/json" \
    -d "{\"role\": \"$ROLE\", \"replicas\": 3}"
done
```

### Scale Down Everything
```bash
for ROLE in MARKETING DEVELOPER TESTER; do
  curl -X POST http://localhost:8080/scale \
    -H "Content-Type: application/json" \
    -d "{\"role\": \"$ROLE\", \"replicas\": 0}"
done
```

---

## URLs & Ports

| Service | URL | Default Port |
|---------|-----|--------------|
| Controller API | http://localhost:8080 | 8080 |
| K3s API | https://<NODE_IP>:6443 | 6443 |
| Grafana (if installed) | http://localhost:3000 | 3000 |

---

## File Locations

| Item | Location |
|------|----------|
| kubeconfig | /etc/rancher/k3s/k3s.yaml |
| Join token | /root/k3s-setup/node-token.txt |
| Control plane IP | /root/k3s-setup/control-plane-ip.txt |
| K3s service logs | journalctl -u k3s |
| K3s agent logs | journalctl -u k3s-agent |

---

## Need Help?

- **Overview:** README.md
- **Deployment:** DEPLOYMENT.md
- **API Docs:** controller/README.md
- **Scripts:** scripts/README.md
- **Architecture:** PROJECT_SUMMARY.md
