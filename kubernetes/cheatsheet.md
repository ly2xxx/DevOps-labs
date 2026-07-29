# Kubernetes Hands-On Cheat Sheet

A comprehensive summary of the Kubernetes resources created, ReplicaSet mechanics, production Namespaces, and step-by-step commands executed during our lab session on Docker Desktop Kubernetes.

---

## 📁 1. Project Files Overview

| File | Resource Type | Description |
| :--- | :--- | :--- |
| [`namespace.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/namespace.yaml) | `Namespace` | Defines the isolated `prod` (production) namespace boundary |
| [`configmap.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/configmap.yaml) | `ConfigMap` | Defines `webserver-configmap` containing HTML content & key-value env vars |
| [`deployment.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/deployment.yaml) | `Deployment` | Manages 5 Nginx pods with resource limits, probes, and volume mounts |
| [`service.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/service.yaml) | `Service` | Exposes Nginx pods internally via ClusterIP on port 80 |
| [`service_nodeport.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/service_nodeport.yaml) | `Service` | Exposes Nginx pods externally on host node port 32008 using NodePort |
| [`curlpod.yaml`](file:///h:/code/yl/DevOps-labs/kubernetes/curlpod.yaml) | `Pod` | Lightweight utility pod (`curlimages/curl`) for in-cluster network testing |

---

## 🔄 2. Full Deployment Cycle (Step-by-Step)

Follow this order of execution for a clean, end-to-end deployment:

### Step 1: Create the ConfigMap
Must be created first so volume mounts in the deployment template can reference it:
```powershell
kubectl apply -f configmap.yaml
```

### Step 2: Deploy the Webserver Application
Applies the Nginx deployment configured with probes and mounting `webserver-configmap` into `/usr/share/nginx/html/`:
```powershell
kubectl apply -f deployment.yaml
```

### Step 3: Expose via NodePort Service
Upgrades or applies the service as a `NodePort` mapping internal port 80 to host port 32008:
```powershell
kubectl apply -f service_nodeport.yaml
```

### Step 4: Deploy In-Cluster Debugging Pod
```powershell
kubectl apply -f curlpod.yaml
```

### Step 5: Force Rollout Restart (If ConfigMap content/mounts were updated)
Ensures all pod replicas restart and pick up the latest mounted ConfigMap files:
```powershell
kubectl rollout restart deployment webserver-deployment
```

---

## 🏢 3. Production Namespace (`prod`) Setup

Namespaces provide logical isolation, resource quotas, and environment separation (`dev`, `staging`, `prod`).

### `namespace.yaml` Manifest
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    environment: production
```

### Deploying Workloads into `prod` Namespace
```powershell
# 1. Create the prod namespace
kubectl apply -f namespace.yaml
# (Or CLI equivalent: kubectl create namespace prod)

# 2. Deploy ConfigMap, Deployment, and Service (ClusterIP) into prod
kubectl apply -f configmap.yaml -n prod
kubectl apply -f deployment.yaml -n prod
kubectl apply -f service.yaml -n prod
# Note: Use service.yaml (ClusterIP) because NodePort (32008) is cluster-wide and bound by the default namespace!

# 3. Inspect resources inside the prod namespace
kubectl get pods -n prod
kubectl get svc -n prod
kubectl get all -n prod

# 4. View resources across ALL namespaces in the cluster
kubectl get pods -A
```

### Cross-Namespace DNS Communication
Pods in another namespace (e.g. `dev`) can access the service in `prod` using Full Qualified Domain Names (FQDN):

$$\text{\texttt{http://<service-name>.<namespace>.svc.cluster.local}}$$

```powershell
# Example: Calling prod service from curlpod in default namespace
kubectl exec curlpod -- curl -s http://web-service.prod.svc.cluster.local
```

---

## 🔍 4. Verification & Inspection Commands

### Check Pod & Service Status
```powershell
# List all running pods
kubectl get pods

# View detailed status of deployment & rollout progress
kubectl describe deployment webserver-deployment
kubectl rollout status deployment webserver-deployment

# View detailed status of service & mapped pod endpoints
kubectl describe svc web-service
kubectl get endpoints web-service
```

### Check ConfigMap Content & Environment Variables
```powershell
kubectl get configmaps
kubectl get configmap webserver-configmap -o yaml

# Verify environment variables inside container
kubectl exec deployment/webserver-deployment -- printenv | grep -E "APP_ENV|MAX_CONNECTIONS"

# Check container startup log output printing the env vars
kubectl logs deployment/webserver-deployment --tail=5
```

### Live Log Streaming
```powershell
# Stream logs live from a deployment
kubectl logs -f deployment/webserver-deployment

# Stream live logs from ALL pod replicas simultaneously
kubectl logs -f -l app=webserver --all-containers
```

---

| **Dynamic HTML (`envsubst`)** | Rendering container env vars into static HTML at startup | `command:` running `envsubst` reading `/tmp/template/index.html` | Submits rendered HTML with `$APP_ENV` & `$MAX_CONNECTIONS` into Nginx web root |
| **Volume Mount (Selective Items)** | Whole files (`index.html`, `nginx.conf`) without dumping extra key/values | `spec.volumes[].configMap.items` (`key` & `path`) | Creates *only* specified key files inside the mounted directory |
| **Volume Mount (All Keys)** | Mounts all keys under `data:` as files | `spec.containers[].volumeMounts` + `spec.volumes[].configMap` | Creates a file for every key in the directory |
| **Environment Variables (`envFrom`)** | Scalar Key/Value configs (`LOG_LEVEL`, `APP_ENV`, `DB_PORT`) | `spec.containers[].envFrom.configMapRef` | Requires Pod restart (`rollout restart`) to update container process env vars |
| **Individual Env Key (`env`)** | Single key mapping (`valueFrom.configMapKeyRef`) | `spec.containers[].env[].valueFrom` | Requires Pod restart to update |

---

## ⚙️ 5. ReplicaSet Architecture & Rollout Management

### Architecture Hierarchy
```text
Deployment (webserver-deployment)
   └── ReplicaSet (webserver-deployment-7c8f765b79) [Revision 3]
          ├── Pod (webserver-deployment-7c8f765b79-dcf5p)
          ├── Pod (webserver-deployment-7c8f765b79-m9skp)
          ├── Pod (webserver-deployment-7c8f765b79-qqnnk)
          ├── Pod (webserver-deployment-7c8f765b79-tq22r)
          └── Pod (webserver-deployment-7c8f765b79-wtcqq)
```

### Understanding ReplicaSets (`kubectl get replicaset`)
* Every time `deployment.yaml` spec is modified or a rollout restart is triggered, Kubernetes creates a **new ReplicaSet**.
* The **pod name** contains the hash identifier of its parent ReplicaSet:
  * Pod: `webserver-deployment-7c8f765b79-dcf5p` $\rightarrow$ ReplicaSet: `webserver-deployment-7c8f765b79`
* Old ReplicaSets are kept (`DESIRED: 0`) to allow instant rollbacks.

### Rollout Commands Reference

```powershell
# 1. Trigger a rolling restart of all pods (zero downtime)
kubectl rollout restart deployment webserver-deployment

# 2. Check current rollout status
kubectl rollout status deployment webserver-deployment

# 3. View revision history
kubectl rollout history deployment webserver-deployment

# 4. View details of a specific revision
kubectl rollout history deployment webserver-deployment --revision=2

# 5. Roll back to the previous revision
kubectl rollout undo deployment webserver-deployment

# 6. Roll back to a specific target revision
kubectl rollout undo deployment webserver-deployment --to-revision=1
```

### Rollback Revision Mechanics
* When you run `kubectl rollout undo`, Kubernetes promotes the target historical ReplicaSet back to active status (`DESIRED: 5`) and sets the current ReplicaSet to `DESIRED: 0`.
* The newly promoted ReplicaSet receives a **new Revision Number** (e.g., rolling back from Revision 3 to Revision 2 creates Revision 4, consuming Revision 2).

---

## 🌐 6. Accessing the Application

### Access from Host Browser (NodePort)
Open browser directly at:
```text
http://localhost:32008
```
Or test via host PowerShell:
```powershell
curl http://localhost:32008
```

### In-Cluster Verification using `curlpod`
Execute `curl` commands directly inside the cluster overlay network:
```powershell
# Test service by DNS name
kubectl exec curlpod -- curl -s http://web-service

# Test service by ClusterIP directly
kubectl exec curlpod -- curl -s http://10.104.21.173
```

### Alternative: Access via `kubectl port-forward`
```powershell
# Forward local host port 8888 to service port 80
kubectl port-forward svc/web-service 8888:80
```
Access at `http://localhost:8888`

---

## 🧪 7. Self-Healing & Scaling Experiments

### Self-Healing Test
Delete a running pod to observe Kubernetes automatically creating a replacement:
```powershell
# Delete a specific pod
kubectl delete pod <pod-name>

# Verify replacement pod is spawned
kubectl get pods
```

### Dynamic Replica Scaling
```powershell
# Scale deployment down to 3 replicas
kubectl scale deployment webserver-deployment --replicas=3

# Scale deployment back to 5 replicas
kubectl scale deployment webserver-deployment --replicas=5
```

---

## 🧹 8. Full Teardown & Cleanup

Remove all resources created during this lab session:

```powershell
# Delete default namespace resources
kubectl delete -f deployment.yaml
kubectl delete -f service_nodeport.yaml
kubectl delete -f service.yaml
kubectl delete -f configmap.yaml
kubectl delete -f curlpod.yaml

# Delete prod namespace and all its resources
kubectl delete -f namespace.yaml
```
