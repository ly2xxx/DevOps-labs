# Kubernetes Hands-On Cheat Sheet

A comprehensive summary of the Kubernetes resources created and commands executed during our lab session on Docker Desktop Kubernetes.

---

## 📁 1. Project Files Overview

| File | Resource Type | Description |
| :--- | :--- | :--- |
| [`deployment.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/deployment.yaml) | `Deployment` | Manages 3-5 Nginx webserver pods with resource limits and probes |
| [`service.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/service.yaml) | `Service` | Exposes Nginx pods internally via ClusterIP on port 80 |
| [`curlpod.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/curlpod.yaml) | `Pod` | Lightweight utility pod (`curlimages/curl`) for in-cluster network debugging |

---

## 🚀 2. Deploying & Managing Applications

### Apply Configurations
```powershell
# Apply all resources in the folder
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f curlpod.yaml
```

### Inspecting Resources
```powershell
# List running pods
kubectl get pods

# View detailed status of deployment
kubectl describe deployment webserver-deployment

# View detailed status of service & mapped endpoint IPs
kubectl describe svc web-service
kubectl get endpoints web-service
```

---

## 🔄 3. Self-Healing & Scaling Experiments

### Self-Healing Test
Delete a running pod to observe Kubernetes automatically replacing it to maintain the requested replica count:
```powershell
# Delete a specific pod
kubectl delete pod webserver-deployment-6dcf4bdfbc-28n8t

# Verify new pod generation
kubectl get pods
```

### Scaling Replicas
Scale the number of running pod instances dynamically:
```powershell
# Scale deployment down to 3 replicas
kubectl scale deployment webserver-deployment --replicas=3
```

---

## 🌐 4. Networking & Accessing Services

### ClusterIP vs. Host Reachability
- **`ClusterIP`** (e.g. `10.104.21.173`) is an internal virtual IP **only reachable within the Kubernetes cluster overlay network**.
- Host machine (Windows OS) cannot directly ping or curl `ClusterIP` addresses.

### In-Cluster Debugging with `curlpod`
Execute `curl` commands directly inside the cluster network to verify service routing:
```powershell
# Test service by DNS name
kubectl exec curlpod -- curl -s http://web-service

# Test service by ClusterIP
kubectl exec curlpod -- curl -s http://10.104.21.173
```

### Accessing Service from Host Machine (`port-forward`)
Forward a local host port to the internal Kubernetes service port:
```powershell
# Forward local port 8888 to service port 80
kubectl port-forward svc/web-service 8888:80
```
Access in browser or host terminal:
```text
http://localhost:8888
```

---

## 🧹 5. Cleanup Commands

```powershell
# Delete created resources
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
kubectl delete -f curlpod.yaml
```
