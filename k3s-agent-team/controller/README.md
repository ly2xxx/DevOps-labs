# AI Agent Team Orchestration Controller

Flask-based API controller that manages K3s AI agent deployments.

## Features

- ✅ RESTful API for task submission
- ✅ Automatic scaling of agent deployments
- ✅ Role-based isolation (MARKETING/DEVELOPER/TESTER)
- ✅ Task tracking and status monitoring
- ✅ Health checks and logging

## API Endpoints

### Health Check
```bash
GET /health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2026-03-22T10:30:00"
}
```

---

### Get Status
```bash
GET /status
```

Response:
```json
{
  "timestamp": "2026-03-22T10:30:00",
  "agents": {
    "MARKETING": {
      "replicas": 2,
      "pods": [
        {
          "name": "marketing-agent-abc123",
          "phase": "Running",
          "ready": true,
          "node": "worker-01"
        }
      ]
    },
    "DEVELOPER": { ... },
    "TESTER": { ... }
  },
  "active_tasks": 3
}
```

---

### Submit Task
```bash
POST /task
Content-Type: application/json

{
  "role": "MARKETING",
  "task": "Analyze Q1 campaign performance",
  "replicas": 2
}
```

Response:
```json
{
  "task_id": "marketing-1711097400",
  "role": "MARKETING",
  "status": "submitted",
  "replicas": 2,
  "message": "Scaled MARKETING agents to 2 replicas"
}
```

---

### Get Task Status
```bash
GET /task/<task_id>
```

Response:
```json
{
  "task_id": "marketing-1711097400",
  "task": {
    "role": "MARKETING",
    "task": "Analyze Q1 campaign performance",
    "replicas": 2,
    "submitted_at": "2026-03-22T10:30:00",
    "status": "running"
  },
  "pods": [ ... ],
  "current_replicas": 2
}
```

---

### Complete Task (Scale Down)
```bash
POST /task/<task_id>/complete
```

Response:
```json
{
  "task_id": "marketing-1711097400",
  "status": "completed",
  "message": "Scaled MARKETING agents to 0 replicas"
}
```

---

### Manual Scale
```bash
POST /scale
Content-Type: application/json

{
  "role": "DEVELOPER",
  "replicas": 5
}
```

Response:
```json
{
  "role": "DEVELOPER",
  "replicas": 5,
  "message": "Scaled DEVELOPER agents to 5 replicas"
}
```

---

## Build & Deploy

### 1. Build Docker Image

```bash
cd controller/

# Build the image
docker build -t agent-controller:latest .

# Or if using K3s local registry
docker build -t localhost:5000/agent-controller:latest .
docker push localhost:5000/agent-controller:latest
```

### 2. Deploy to K3s

```bash
# Apply all K8s resources first
kubectl apply -f ../k8s/namespaces/
kubectl apply -f ../k8s/deployments/
kubectl apply -f ../k8s/quotas/
kubectl apply -f ../k8s/network-policies/

# Deploy the controller
kubectl apply -f controller-deployment.yaml

# Verify
kubectl get pods -n coordinator
kubectl logs -n coordinator -l app=agent-controller -f
```

### 3. Test the API

```bash
# Port-forward to access locally
kubectl port-forward -n coordinator svc/agent-controller 8080:8080

# In another terminal, test endpoints
curl http://localhost:8080/health

curl http://localhost:8080/status

# Submit a task
curl -X POST http://localhost:8080/task \
  -H "Content-Type: application/json" \
  -d '{"role": "MARKETING", "task": "Test task", "replicas": 1}'

# Check task status
curl http://localhost:8080/task/marketing-1711097400

# Complete task (scale down)
curl -X POST http://localhost:8080/task/marketing-1711097400/complete
```

---

## Usage Examples

### Example 1: Run a Marketing Campaign Analysis

```bash
# Submit task
TASK_ID=$(curl -s -X POST http://localhost:8080/task \
  -H "Content-Type: application/json" \
  -d '{
    "role": "MARKETING",
    "task": "Analyze Q1 social media campaign ROI",
    "replicas": 2
  }' | jq -r '.task_id')

echo "Task ID: $TASK_ID"

# Wait for pods to be ready
while true; do
  STATUS=$(curl -s http://localhost:8080/task/$TASK_ID | jq -r '.pods[0].ready')
  if [ "$STATUS" == "true" ]; then
    echo "Agents ready!"
    break
  fi
  echo "Waiting for agents..."
  sleep 5
done

# ... agents do their work ...

# Complete task and scale down
curl -X POST http://localhost:8080/task/$TASK_ID/complete
```

### Example 2: Emergency Scale-Up

```bash
# Immediate scale-up for urgent task
curl -X POST http://localhost:8080/scale \
  -H "Content-Type: application/json" \
  -d '{"role": "DEVELOPER", "replicas": 5}'
```

### Example 3: Monitoring Script

```bash
#!/bin/bash
# monitor-agents.sh

while true; do
  clear
  echo "=== AI Agent Team Status ==="
  echo ""
  curl -s http://localhost:8080/status | jq '
    {
      timestamp: .timestamp,
      active_tasks: .active_tasks,
      marketing_replicas: .agents.MARKETING.replicas,
      developer_replicas: .agents.DEVELOPER.replicas,
      tester_replicas: .agents.TESTER.replicas
    }
  '
  echo ""
  echo "Press Ctrl+C to exit"
  sleep 5
done
```

---

## Configuration

Environment variables (set in `controller-deployment.yaml`):

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | HTTP server port |
| `PYTHONUNBUFFERED` | `1` | Unbuffered logging |

---

## Permissions

The controller requires these Kubernetes permissions:

- **Deployments:** `get`, `list`, `watch`, `patch`, `update`
- **Pods:** `get`, `list`, `watch`
- **Namespaces:** `get`, `list`

These are granted via the `agent-controller` ServiceAccount and ClusterRole.

---

## Troubleshooting

### Controller pod won't start

```bash
# Check logs
kubectl logs -n coordinator -l app=agent-controller

# Check RBAC
kubectl get clusterrolebinding agent-controller-binding
kubectl describe clusterrole agent-controller-role
```

### Can't scale deployments

```bash
# Verify permissions
kubectl auth can-i patch deployments --as=system:serviceaccount:coordinator:agent-controller -n marketing-agents

# Should return "yes"
```

### API unreachable

```bash
# Check service
kubectl get svc -n coordinator agent-controller

# Check endpoints
kubectl get endpoints -n coordinator agent-controller

# Port-forward for testing
kubectl port-forward -n coordinator svc/agent-controller 8080:8080
```

---

## Production Considerations

1. **Authentication:** Add API key authentication for `/task` endpoint
2. **Rate Limiting:** Prevent abuse with request throttling
3. **Task Queue:** Use Redis/RabbitMQ for production task queue
4. **Logging:** Ship logs to centralized system (Loki, Elasticsearch)
5. **Metrics:** Expose Prometheus metrics for monitoring
6. **High Availability:** Run 2+ controller replicas with leader election

---

## Next Steps

- [ ] Add webhook support for task completion notifications
- [ ] Implement task queue persistence (Redis)
- [ ] Add Prometheus metrics endpoint
- [ ] Create dashboard (Grafana)
- [ ] Add authentication middleware
