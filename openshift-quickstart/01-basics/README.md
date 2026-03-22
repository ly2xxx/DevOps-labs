# Lab 1: OpenShift Basics

**Foundation for Helm + Nexus and Helm + ArgoCD labs**

---

## 📋 What You'll Learn

- Basic OpenShift CLI (`oc`) commands
- Projects (namespaces)
- Deployments
- Services and Routes
- ConfigMaps
- Basic YAML deployments

---

## 🎯 Prerequisites

- [ ] OpenShift cluster access (CRC or real cluster)
- [ ] `oc` CLI installed
- [ ] Basic Kubernetes knowledge (helpful but not required)

---

## 🚀 Quick Start

### Step 1: Login to OpenShift

```bash
# Using CRC (local)
eval $(crc oc-env)
oc login -u developer -p developer https://api.crc.testing:6443

# Using real cluster
oc login --token=<your-token> --server=https://api.cluster.com:6443
```

### Step 2: Create a Project

```bash
# Create project
oc new-project my-first-app

# Verify
oc project
oc status
```

### Step 3: Deploy Sample App

**Simple deployment:**
```bash
cd examples

# Deploy
oc apply -f simple-deployment.yaml

# Check status
oc get pods
oc get svc
oc get route
```

**App with configuration:**
```bash
# Deploy with ConfigMap
oc apply -f app-with-config.yaml

# Verify
oc get all
oc describe deployment webapp
```

---

## 📚 Core Concepts

### **Projects (Namespaces)**
OpenShift's way of organizing resources. Similar to Kubernetes namespaces but with additional features.

```bash
# Create project
oc new-project dev-environment

# List projects
oc projects

# Switch project
oc project dev-environment

# Delete project (careful!)
oc delete project dev-environment
```

### **Deployments**
Define how your application should run.

```bash
# Create deployment
oc create deployment nginx --image=nginx:latest

# Scale
oc scale deployment nginx --replicas=3

# Check rollout status
oc rollout status deployment/nginx
```

### **Services**
Internal networking for your pods.

```bash
# Expose deployment as service
oc expose deployment nginx --port=80

# Check service
oc get svc nginx

# Describe
oc describe svc nginx
```

### **Routes** (OpenShift-specific)
External access to your services.

```bash
# Create route
oc expose svc nginx

# Get route URL
oc get route nginx

# Access
curl http://$(oc get route nginx -o jsonpath='{.spec.host}')
```

### **ConfigMaps**
Configuration data for your apps.

```bash
# Create from literal
oc create configmap app-config --from-literal=environment=dev

# Create from file
oc create configmap app-config --from-file=config.yaml

# View
oc get configmap app-config -o yaml
```

---

## 🔍 Useful Commands

### **Get Resources**
```bash
oc get pods
oc get deployments
oc get services
oc get routes
oc get all  # Everything in current project
```

### **Describe (detailed info)**
```bash
oc describe pod <pod-name>
oc describe deployment <deployment-name>
```

### **Logs**
```bash
# Follow logs
oc logs -f <pod-name>

# Last 100 lines
oc logs --tail=100 <pod-name>

# Previous container (if crashed)
oc logs --previous <pod-name>
```

### **Execute Commands**
```bash
# Interactive shell
oc rsh <pod-name>

# Run single command
oc exec <pod-name> -- ls -la
```

### **Port Forwarding** (local testing)
```bash
oc port-forward <pod-name> 8080:8080

# Access locally
curl http://localhost:8080
```

---

## 📝 Example Workflows

### **Deploy → Scale → Update**

```bash
# 1. Deploy
oc create deployment webapp --image=nginx:1.20

# 2. Expose
oc expose deployment webapp --port=80
oc expose svc webapp

# 3. Scale
oc scale deployment webapp --replicas=3

# 4. Update image
oc set image deployment/webapp nginx=nginx:1.21

# 5. Check rollout
oc rollout status deployment/webapp

# 6. Rollback if needed
oc rollout undo deployment/webapp
```

---

## 🛠️ Troubleshooting

### **Pod not starting?**
```bash
# Check pod status
oc get pods

# Describe to see events
oc describe pod <pod-name>

# Check logs
oc logs <pod-name>
```

### **Can't access via route?**
```bash
# Check route exists
oc get route

# Check service
oc get svc

# Check endpoints
oc get endpoints
```

### **Configuration issues?**
```bash
# Check ConfigMap
oc get configmap

# Verify mounted in pod
oc describe pod <pod-name> | grep -A 5 Mounts
```

---

## ✅ Verification Checklist

After this lab, you should be able to:

- [ ] Login to OpenShift cluster
- [ ] Create a project
- [ ] Deploy an application from YAML
- [ ] Expose a service via Route
- [ ] Access application via browser/curl
- [ ] View logs
- [ ] Scale a deployment
- [ ] Use ConfigMaps

---

## 🚀 Next Steps

Once comfortable with these basics:

👉 **[Lab 2: Helm + Nexus](../02-helm-nexus-lab/README.md)**  
Learn centralized artifact management

👉 **[Lab 3: Helm + ArgoCD](../03-helm-argocd-lab/README.md)**  
Experience GitOps automation

---

## 📚 Additional Resources

- [OpenShift Docs](https://docs.openshift.com/)
- [OpenShift Cheatsheet](../cheatsheet.md)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)

---

**Ready?** Try the examples in `examples/` folder, then move on to Lab 2! 🎯
