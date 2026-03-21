# OpenShift CLI Quick Reference

## 🔐 Login & Authentication

```powershell
# Login with token (from web console: Copy login command)
oc login --token=<token> --server=<server-url>

# Login with username/password
oc login -u developer -p developer <server-url>

# Get current user
oc whoami

# Get server URL
oc whoami --show-server

# Logout
oc logout
```

---

## 📁 Projects (Namespaces)

```powershell
# Create project
oc new-project <name>

# List projects
oc projects

# Switch project
oc project <name>

# Show current project
oc project

# Delete project
oc delete project <name>

# Project details
oc describe project <name>
```

---

## 🚀 Deployments

```powershell
# Deploy from Git
oc new-app https://github.com/user/repo.git --name=<app-name>

# Deploy from Docker image
oc new-app --docker-image=nginx:alpine --name=<app-name>

# Deploy from local Dockerfile
oc new-build --strategy docker --binary --name=<app-name>
oc start-build <app-name> --from-dir=. --follow

# Create deployment
oc create deployment <name> --image=<image>

# Delete deployment
oc delete deployment <name>

# Scale deployment
oc scale deployment/<name> --replicas=3

# Autoscale
oc autoscale deployment/<name> --min=2 --max=5 --cpu-percent=80
```

---

## 🔍 Viewing Resources

```powershell
# List all resources
oc get all

# List specific resources
oc get pods
oc get deployments
oc get services
oc get routes
oc get buildconfigs
oc get builds

# Watch resources (live updates)
oc get pods -w

# Detailed info
oc describe pod/<pod-name>
oc describe deployment/<name>

# Get in YAML/JSON
oc get pod/<pod-name> -o yaml
oc get deployment/<name> -o json

# Get specific field
oc get route/<name> -o jsonpath='{.spec.host}'
```

---

## 🌐 Routes (External Access)

```powershell
# Expose service as route
oc expose svc/<service-name>

# Expose with custom hostname
oc expose svc/<service-name> --hostname=myapp.example.com

# Expose with specific port
oc expose svc/<service-name> --port=8080

# Get route URL
oc get route <name>
oc get route <name> -o jsonpath='{.spec.host}'

# Delete route
oc delete route <name>

# Enable HTTPS
oc create route edge --service=<service-name> --hostname=<host>
```

---

## 📜 Logs & Debugging

```powershell
# View pod logs
oc logs <pod-name>

# Follow logs (live)
oc logs -f <pod-name>

# Logs from specific container (multi-container pod)
oc logs <pod-name> -c <container-name>

# Previous container logs (after crash)
oc logs <pod-name> --previous

# Build logs
oc logs bc/<build-config-name>
oc logs build/<build-name>

# All events in project
oc get events

# Shell access to pod
oc exec -it <pod-name> -- /bin/bash
oc exec -it <pod-name> -- /bin/sh

# Run command in pod
oc exec <pod-name> -- ls /app

# Copy files to/from pod
oc cp <local-file> <pod-name>:/path/
oc cp <pod-name>:/path/file <local-path>

# Port forward
oc port-forward <pod-name> 8080:80
```

---

## ⚙️ Configuration

```powershell
# Create ConfigMap
oc create configmap <name> --from-literal=KEY=value
oc create configmap <name> --from-file=config.txt

# Create Secret
oc create secret generic <name> --from-literal=password=secret
oc create secret generic <name> --from-file=ssh-key=~/.ssh/id_rsa

# Set env from ConfigMap
oc set env deployment/<name> --from=configmap/<cm-name>

# Set env from Secret
oc set env deployment/<name> --from=secret/<secret-name>

# Set env variable directly
oc set env deployment/<name> VAR=value

# List env variables
oc set env deployment/<name> --list

# View ConfigMap/Secret
oc get configmap <name> -o yaml
oc get secret <name> -o yaml
```

---

## 🔨 Build Management

```powershell
# Start build
oc start-build <build-config-name>

# Start build from local directory
oc start-build <build-config-name> --from-dir=.

# Follow build logs
oc start-build <build-config-name> --follow

# Cancel build
oc cancel-build <build-name>

# Delete build
oc delete build <build-name>

# View build config
oc describe bc/<build-config-name>
```

---

## 📦 Labels & Selectors

```powershell
# Add label to resource
oc label pod/<pod-name> environment=production

# Remove label
oc label pod/<pod-name> environment-

# Get resources by label
oc get pods -l app=myapp
oc get all -l app=myapp

# Update labels
oc label pod/<pod-name> tier=frontend --overwrite
```

---

## 💾 Persistent Storage

```powershell
# Create PersistentVolumeClaim
oc create -f pvc.yaml

# List PVCs
oc get pvc

# Describe PVC
oc describe pvc/<name>

# Mount PVC to deployment
oc set volume deployment/<name> --add --type=pvc --claim-name=<pvc-name> --mount-path=/data

# Delete PVC
oc delete pvc/<name>
```

---

## 🔄 Updates & Rollbacks

```powershell
# Update image
oc set image deployment/<name> <container-name>=<new-image>

# Trigger rollout
oc rollout restart deployment/<name>

# Rollout status
oc rollout status deployment/<name>

# Rollout history
oc rollout history deployment/<name>

# Rollback to previous version
oc rollout undo deployment/<name>

# Rollback to specific revision
oc rollout undo deployment/<name> --to-revision=2
```

---

## 🛡️ Security & RBAC

```powershell
# Get service accounts
oc get sa

# Create service account
oc create sa <name>

# Add role to user
oc adm policy add-role-to-user <role> <username>

# Add cluster role
oc adm policy add-cluster-role-to-user <role> <username>

# View roles
oc get roles
oc get clusterroles

# Check permissions
oc auth can-i create pods
oc auth can-i delete deployment
```

---

## 🔧 Resource Limits

```powershell
# Set resource limits
oc set resources deployment/<name> \
  --limits=cpu=200m,memory=512Mi \
  --requests=cpu=100m,memory=256Mi

# Set probe (health check)
oc set probe deployment/<name> --liveness \
  --get-url=http://:8080/health --initial-delay-seconds=30

# Set readiness probe
oc set probe deployment/<name> --readiness \
  --get-url=http://:8080/ready --initial-delay-seconds=5
```

---

## 🌍 Context & Cluster Info

```powershell
# Get cluster info
oc cluster-info

# Get API server
oc whoami --show-server

# Get current context
oc whoami --show-context

# Switch context
oc config use-context <context-name>

# View kubeconfig
oc config view

# Get nodes
oc get nodes

# OpenShift version
oc version
```

---

## 🧹 Cleanup

```powershell
# Delete resource
oc delete <resource-type>/<name>

# Delete all resources with label
oc delete all -l app=myapp

# Delete all in project (careful!)
oc delete all --all

# Delete project (deletes all resources)
oc delete project <name>

# Force delete stuck pod
oc delete pod <name> --force --grace-period=0
```

---

## 🎛️ Advanced

```powershell
# Apply YAML
oc apply -f deployment.yaml

# Create from YAML
oc create -f config.yaml

# Replace resource
oc replace -f updated.yaml

# Patch resource
oc patch deployment/<name> -p '{"spec":{"replicas":5}}'

# Export resource
oc get deployment/<name> -o yaml > deployment.yaml

# Edit resource
oc edit deployment/<name>

# Run temporary pod
oc run tmp-pod --image=alpine --rm -it -- /bin/sh

# Debug pod
oc debug pod/<pod-name>
```

---

## 🔌 Helm Integration

```powershell
# Add Helm repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install chart
helm install <release-name> <chart>

# Install with custom values
helm install <release-name> <chart> -f values.yaml

# List releases
helm list

# Upgrade release
helm upgrade <release-name> <chart>

# Rollback release
helm rollback <release-name> <revision>

# Uninstall release
helm uninstall <release-name>
```

---

## 💡 Quick Shortcuts

```powershell
# Get pod name (when you have one pod with label)
$pod = oc get pod -l app=myapp -o jsonpath='{.items[0].metadata.name}'

# Get route URL
$url = oc get route myapp -o jsonpath='{.spec.host}'
echo "http://$url"

# Shell into first pod matching label
$pod = oc get pod -l app=myapp -o jsonpath='{.items[0].metadata.name}'
oc exec -it $pod -- /bin/bash

# Delete all failed pods
oc delete pod --field-selector=status.phase=Failed

# Watch pod restart count
oc get pods --watch-only -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount
```

---

## 🆘 Common Troubleshooting Commands

```powershell
# Why is pod not starting?
oc describe pod/<pod-name>
oc logs <pod-name>
oc get events --sort-by='.lastTimestamp'

# Check resource quota
oc describe quota
oc describe limitrange

# Check service endpoints
oc get endpoints

# Test service connectivity
oc run tmp --image=alpine --rm -it -- wget -qO- http://<service>:80

# View image pull status
oc describe pod/<pod-name> | findstr -i "pull"

# Check pod resource usage
oc adm top pods
oc adm top nodes
```

---

**Tip:** Most `kubectl` commands work with `oc` - OpenShift is Kubernetes-compatible!

**Save this file as:** `oc-cheatsheet.txt` for quick reference during your OpenShift journey.
