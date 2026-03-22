# OpenShift Example YAML Files

**Ready-to-deploy example configurations for learning and experimentation.**

---

## 📁 Files in This Directory

### 1. simple-deployment.yaml
**What it deploys:**
- NGINX web server (2 replicas)
- Service (ClusterIP)
- Route (external access with TLS)

**Use when:**
- Learning basic deployment structure
- Quick test of OpenShift Routes
- Template for simple web apps

**Deploy:**
```powershell
oc apply -f simple-deployment.yaml
oc get all
oc get route simple-nginx
```

**Access:**
```powershell
# Get URL
$url = oc get route simple-nginx -o jsonpath='{.spec.host}'
curl "https://$url"
```

**Cleanup:**
```powershell
oc delete -f simple-deployment.yaml
```

---

### 2. app-with-config.yaml
**What it deploys:**
- NGINX app (3 replicas with autoscaling)
- ConfigMap (application config)
- Secret (sensitive data)
- Service (ClusterIP)
- Route (external access)
- HorizontalPodAutoscaler (scales 2-5 pods)

**Use when:**
- Learning ConfigMaps and Secrets
- Understanding environment variables
- Setting up autoscaling
- Complete production-like deployment

**Deploy:**
```powershell
oc apply -f app-with-config.yaml
oc get all
oc get hpa
```

**Verify environment variables:**
```powershell
# Get first pod name
$pod = oc get pod -l app=demo-app -o jsonpath='{.items[0].metadata.name}'

# Check env vars
oc exec $pod -- env | Select-String "APP_NAME|ENVIRONMENT|LOG_LEVEL"
```

**View secret values:**
```powershell
# Secrets are base64 encoded
oc get secret app-secrets -o jsonpath='{.data.DB_PASSWORD}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

**Cleanup:**
```powershell
oc delete -f app-with-config.yaml
```

---

## 🎓 How to Use These Examples

### Method 1: Deploy As-Is (Quickest)
```powershell
# Create project
oc new-project examples-demo

# Deploy
oc apply -f <filename>.yaml

# Check
oc get all
```

---

### Method 2: Customize First (Recommended)
```powershell
# Copy to your working directory
cp simple-deployment.yaml my-deployment.yaml

# Edit with your changes
notepad my-deployment.yaml

# Deploy
oc apply -f my-deployment.yaml
```

**Common customizations:**
- Change `replicas: 2` to scale
- Change `image:` to use your own
- Change `name:` to avoid conflicts
- Add more environment variables
- Adjust resource limits

---

### Method 3: Learn by Breaking
```powershell
# Deploy
oc apply -f simple-deployment.yaml

# Experiment
oc scale deployment simple-nginx --replicas=5
oc set image deployment/simple-nginx nginx=nginx:latest
oc delete pod <pod-name>  # Watch it recreate

# Observe
oc get pods -w
oc logs <pod-name>
oc describe deployment simple-nginx
```

---

## 📚 Understanding the YAML Structure

### Basic Deployment Pattern
```yaml
apiVersion: apps/v1          # API version
kind: Deployment             # Resource type
metadata:                    # Names, labels, etc.
  name: my-app
spec:                        # Desired state
  replicas: 2
  selector:                  # Which pods this manages
    matchLabels:
      app: my-app
  template:                  # Pod template
    metadata:
      labels:                # Must match selector
        app: my-app
    spec:
      containers:            # Container definitions
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
```

---

### ConfigMap Pattern
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  KEY: value               # Plain text key-value pairs
  ANOTHER_KEY: another-value

# Then reference in deployment:
env:
- name: MY_ENV_VAR
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: KEY
```

---

### Secret Pattern
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  password: cGFzc3dvcmQ=   # Base64 encoded value
  # Encode: echo -n "password" | base64

# Then reference in deployment:
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secrets
      key: password
```

---

### Route Pattern (OpenShift-specific)
```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: my-app
spec:
  to:
    kind: Service          # Routes traffic to this service
    name: my-app
  port:
    targetPort: http       # Service port name
  tls:
    termination: edge      # TLS at route level
    insecureEdgeTerminationPolicy: Redirect  # Force HTTPS
```

---

## 🔧 Modifying Examples for Your Use

### Change the Image
```yaml
# In deployment spec.template.spec.containers:
- name: app
  image: your-registry/your-image:tag
```

---

### Add Volume Mount
```yaml
# In deployment spec.template.spec:
volumes:
- name: data
  emptyDir: {}

# In container spec:
volumeMounts:
- name: data
  mountPath: /app/data
```

---

### Add More Environment Variables
```yaml
env:
- name: CUSTOM_VAR
  value: "my-value"
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
```

---

### Adjust Resource Limits
```yaml
resources:
  requests:
    memory: "256Mi"     # Guaranteed minimum
    cpu: "250m"
  limits:
    memory: "512Mi"     # Maximum allowed
    cpu: "500m"
```

---

## 💡 Pro Tips

### Tip 1: Validate Before Applying
```powershell
# Dry run (check for errors without deploying)
oc apply -f my-deployment.yaml --dry-run=client

# Server-side validation
oc apply -f my-deployment.yaml --dry-run=server
```

---

### Tip 2: Generate YAML from Running Resources
```powershell
# Export deployment as YAML
oc get deployment simple-nginx -o yaml > my-deployment.yaml

# Edit and reapply
notepad my-deployment.yaml
oc apply -f my-deployment.yaml
```

---

### Tip 3: Use Labels to Manage Groups
```powershell
# Add label to resources
oc label deployment simple-nginx environment=dev

# Delete all resources with label
oc delete all -l environment=dev
```

---

### Tip 4: Multiple Resources in One File
Use `---` separator (as shown in the examples):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1
---
apiVersion: v1
kind: Service
metadata:
  name: app2
```

---

## 🚨 Common Issues

### Issue: "Error from server: already exists"
**Solution:** Resource already deployed
```powershell
# Delete first
oc delete -f <filename>.yaml

# Or use replace
oc replace -f <filename>.yaml --force
```

---

### Issue: "Unable to connect to the server"
**Solution:** Not logged in
```powershell
# Login first
oc login --token=<token> --server=<server>

# Or get login command from web console
```

---

### Issue: "No resources found"
**Solution:** Wrong project
```powershell
# Check current project
oc project

# Switch to correct project
oc project <project-name>
```

---

## 📖 Next Steps

After trying these examples:

1. **Modify** them for your own apps
2. **Combine** patterns (ConfigMap + Secret + PVC)
3. **Create** your own templates
4. **Learn** about:
   - StatefulSets (for databases)
   - Jobs and CronJobs (for tasks)
   - NetworkPolicies (for security)
   - Operators (for complex apps)

---

## 🔗 Related Resources

- **Main guide:** `../README.md`
- **Command reference:** `../cheatsheet.md`
- **OpenShift docs:** https://docs.openshift.com/
- **Kubernetes docs:** https://kubernetes.io/docs/ (most concepts apply)

---

**Happy deploying!** 🚀

If you create something cool, save it here for future reference!
