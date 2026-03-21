# OpenShift Quick Start Guide
**Time to complete: ~45 minutes | Cost: Free tier**

## 🎯 What You'll Learn

By the end of this guide, you'll understand:
- **OpenShift basics**: Enterprise Kubernetes platform from Red Hat
- **Developer Sandbox**: Free cloud-based OpenShift cluster (no installation)
- **Container deployment**: Deploy apps using source code, Docker images, and Helm
- **Routes & Services**: Expose applications to external traffic
- **OpenShift CLI (`oc`)**: Command-line management

## 📚 The Big Picture

```
┌─────────────────────────────────────────────────────────┐
│              OpenShift (Kubernetes++)                    │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │ Developer  │  │   Admin    │  │  Operator  │       │
│  │ Perspective│  │ Perspective│  │    Hub     │       │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘       │
│        │                │                │              │
│        └────────────────┴────────────────┘              │
│                         │                               │
│              ┌──────────▼──────────┐                    │
│              │   Kubernetes Core   │                    │
│              └──────────┬──────────┘                    │
│                         │                               │
└─────────────────────────┼───────────────────────────────┘
                          │
                          ▼
            ┌──────────────────────────┐
            │    Container Runtime     │
            │  (Pods, Services, etc.)  │
            │                          │
            │  - Applications          │
            │  - Databases             │
            │  - Services              │
            └──────────────────────────┘
```

### Key Concepts

1. **OpenShift vs Kubernetes**
   - OpenShift = Kubernetes + Developer tools + Security + CI/CD
   - Built-in image registry
   - Routes (simplified ingress)
   - Source-to-Image (S2I) builds

2. **Projects**
   - Kubernetes namespaces with RBAC
   - Logical grouping of resources
   - Isolation between teams/apps

3. **Routes**
   - OpenShift abstraction over Kubernetes Ingress
   - Automatic SSL/TLS termination
   - Easy external access

4. **Builds & DeploymentConfigs**
   - Build from source code → container image
   - Automatic deployments
   - Rollback support

## 🚀 Hands-On Labs (45 minutes)

### Lab 1: Developer Sandbox Setup (5 min)
**Goal:** Get free cloud-based OpenShift cluster

1. **Sign up for Developer Sandbox:**
   - Go to: https://developers.redhat.com/developer-sandbox
   - Click **"Start your free trial"**
   - Create Red Hat account (free, no credit card)
   - Activate sandbox

2. **Access web console:**
   - Click **"Launch"** after activation
   - Opens OpenShift web console
   - Choose **Developer** perspective (top-left dropdown)

3. **Install `oc` CLI:**
   ```powershell
   # Windows (via winget)
   winget install RedHat.OpenShift-Client
   
   # Verify
   oc version --client
   ```

**Key takeaway:** Developer Sandbox gives you 30-day access to real OpenShift cluster - no installation required!

---

### Lab 2: Deploy Your First App from Source (10 min)
**Goal:** Deploy Node.js app from GitHub using Source-to-Image (S2I)

1. **Create a project:**
   - In web console, click **"+Add"** → **"Create Project"**
   - Name: `hello-openshift`
   - Click **"Create"**

2. **Deploy from Git:**
   - Click **"+Add"** → **"Import from Git"**
   - Git Repo URL: `https://github.com/sclorg/nodejs-ex.git`
   - OpenShift detects Node.js automatically
   - Application name: `nodejs-sample`
   - Click **"Create"**

3. **Watch the build:**
   - Click **"Topology"** view
   - See the build progress (circle icon)
   - Wait for pod to turn blue (running)
   - Build takes ~2-3 minutes

4. **Access the app:**
   - Click the route icon (arrow icon on deployment)
   - Opens in new tab: "Welcome to your Node.js application on OpenShift"

**Via CLI:**
```powershell
# Login (get token from web console: User icon → Copy login command)
oc login --token=<your-token> --server=<your-server>

# Create project
oc new-project hello-openshift

# Deploy from Git
oc new-app https://github.com/sclorg/nodejs-ex.git --name=nodejs-sample

# Expose route
oc expose svc/nodejs-sample

# Get URL
oc get route nodejs-sample
```

**Key takeaway:** OpenShift builds from source automatically - no Dockerfile needed!

---

### Lab 3: Deploy from Container Image (10 min)
**Goal:** Deploy existing Docker image from registry

1. **Create new project:**
   ```powershell
   oc new-project container-demo
   ```

2. **Deploy NGINX:**
   ```powershell
   # Create deployment from Docker Hub
   oc new-app --docker-image=nginx:alpine --name=my-nginx
   
   # Expose route
   oc expose svc/my-nginx --port=80
   
   # Get route
   oc get route my-nginx
   ```

3. **Test the app:**
   ```powershell
   # Get URL
   $route = oc get route my-nginx -o jsonpath='{.spec.host}'
   
   # Open in browser or curl
   curl "http://$route"
   ```

**Via web console:**
- **"+Add"** → **"Container images"**
- Image name: `nginx:alpine`
- Application name: `my-nginx`
- Create route: ✅ checked
- **"Create"**

**Key takeaway:** Deploy any public Docker image in seconds!

---

### Lab 4: Deploy with Helm Charts (15 min)
**Goal:** Use Helm to deploy PostgreSQL database

1. **Install Helm** (if not already):
   ```powershell
   winget install Helm.Helm
   helm version
   ```

2. **Add Bitnami repository:**
   ```powershell
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```

3. **Create project:**
   ```powershell
   oc new-project database-demo
   ```

4. **Deploy PostgreSQL:**
   ```powershell
   helm install my-postgres bitnami/postgresql \
     --set auth.postgresPassword=admin123 \
     --set auth.database=testdb \
     --set primary.persistence.size=1Gi
   ```

5. **Check deployment:**
   ```powershell
   # Wait for pod to be ready
   oc get pods -w
   # Press Ctrl+C when Running
   
   # Get service
   oc get svc
   ```

6. **Connect to database:**
   ```powershell
   # Get pod name
   $pod = oc get pod -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}'
   
   # Connect
   oc exec -it $pod -- psql -U postgres -d testdb
   ```

   **Inside PostgreSQL:**
   ```sql
   \l              -- List databases
   \dt             -- List tables
   CREATE TABLE test (id INT, name VARCHAR(50));
   INSERT INTO test VALUES (1, 'OpenShift Demo');
   SELECT * FROM test;
   \q              -- Quit
   ```

**Key takeaway:** Helm charts work seamlessly on OpenShift!

---

### Lab 5: Environment Variables & ConfigMaps (5 min)
**Goal:** Configure apps with environment variables

1. **Create ConfigMap:**
   ```powershell
   oc create configmap app-config \
     --from-literal=APP_NAME="OpenShift Quick Start" \
     --from-literal=ENVIRONMENT="sandbox"
   
   # View ConfigMap
   oc get configmap app-config -o yaml
   ```

2. **Create Secret:**
   ```powershell
   oc create secret generic db-credentials \
     --from-literal=username=admin \
     --from-literal=password=secret123
   
   # View (values are base64 encoded)
   oc get secret db-credentials -o yaml
   ```

3. **Deploy app with environment variables:**
   ```powershell
   # Create deployment
   oc create deployment env-demo --image=nginx:alpine
   
   # Add env from ConfigMap
   oc set env deployment/env-demo --from=configmap/app-config
   
   # Add env from Secret
   oc set env deployment/env-demo --from=secret/db-credentials
   
   # Verify
   oc set env deployment/env-demo --list
   ```

**Key takeaway:** Separate config from code using ConfigMaps and Secrets!

---

## 🎓 Essential Commands Reference

### Project Management
```powershell
oc new-project <name>           # Create project
oc projects                     # List projects
oc project <name>               # Switch project
oc delete project <name>        # Delete project
```

### Deployment
```powershell
oc new-app <source>             # Deploy from source/image
oc get all                      # List all resources
oc get pods                     # List pods
oc get deployments              # List deployments
oc get services                 # List services
oc get routes                   # List routes
```

### Routes (Exposure)
```powershell
oc expose svc/<name>            # Create route for service
oc get route <name>             # Get route URL
oc delete route <name>          # Delete route
```

### Logs & Debugging
```powershell
oc logs <pod-name>              # View logs
oc logs -f <pod-name>           # Follow logs
oc exec -it <pod> -- /bin/bash  # Shell access
oc describe pod <name>          # Detailed info
oc port-forward <pod> 8080:80   # Port forwarding
```

### Scaling
```powershell
oc scale deployment/<name> --replicas=3  # Scale deployment
oc autoscale deployment/<name> --min=2 --max=5 --cpu-percent=80
```

---

## 💡 Common Patterns

### 1. Deploy Custom Dockerfile

**Create Dockerfile:**
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
```

**Build and deploy:**
```powershell
# Create build config
oc new-build --strategy docker --binary --name=custom-app

# Start build (from current directory)
oc start-build custom-app --from-dir=. --follow

# Create deployment
oc new-app custom-app

# Expose
oc expose svc/custom-app
```

---

### 2. Health Checks

```powershell
# Add readiness probe
oc set probe deployment/my-nginx --readiness \
  --get-url=http://:80/ --initial-delay-seconds=5

# Add liveness probe
oc set probe deployment/my-nginx --liveness \
  --get-url=http://:80/ --initial-delay-seconds=10
```

---

### 3. Resource Limits

```powershell
oc set resources deployment/my-nginx \
  --limits=cpu=200m,memory=512Mi \
  --requests=cpu=100m,memory=256Mi
```

---

## 🚨 Free Tier Limits (Developer Sandbox)

**What's included (free):**
- ✅ 30-day access
- ✅ 2 projects (namespaces)
- ✅ Limited resources (good for learning/demos)
- ✅ All OpenShift features
- ✅ Automatic sleep after 8 hours idle
- ✅ Web console + CLI access

**Limitations:**
- ❌ No persistent volumes (data lost on pod restart)
- ❌ Limited CPU/memory
- ❌ Projects deleted after 30 days

**After 30 days:**
- Renew for another 30 days (repeat as needed)
- Or install OpenShift Local for unlimited offline use

---

## 📖 Next Steps

After completing these labs:

1. **OpenShift Local** (unlimited, runs on your laptop):
   - See: `C:\code\openshift-local-lab\` for detailed guide
   - Download: https://developers.redhat.com/products/openshift-local
   - No internet needed after installation

2. **Learn operators:**
   - Explore **OperatorHub** in web console
   - Deploy databases, monitoring, etc. with one click

3. **CI/CD with Tekton:**
   - Explore **Pipelines** section in web console
   - Build complete CI/CD workflows

4. **Advanced topics:**
   - Service Mesh (Istio)
   - Serverless (Knative)
   - GitOps with ArgoCD

---

## 🆘 Troubleshooting

**Can't login to CLI:**
- Get token from web console: User icon → **"Copy login command"**
- Paste the full `oc login` command

**Build failed:**
- Check logs: `oc logs bc/<build-config-name>`
- Common issue: Wrong Git URL or branch

**Pod not starting:**
```powershell
# Check events
oc describe pod <pod-name>

# Check logs
oc logs <pod-name>

# Check resource quotas
oc describe quota
```

**Route not working:**
- Verify service: `oc get svc`
- Verify route: `oc get route`
- Check pod is running: `oc get pods`

---

## 📁 Additional Resources

**Official Docs:**
- OpenShift Documentation: https://docs.openshift.com/
- Interactive Learning: https://learn.openshift.com/
- Developer Guide: https://docs.openshift.com/container-platform/latest/applications/index.html

**Community:**
- Red Hat Developer: https://developers.redhat.com/
- OpenShift Blog: https://www.openshift.com/blog
- Stack Overflow: [openshift] tag

---

## 🎯 Quick Comparison

| Feature | OpenShift | Kubernetes | Docker |
|---------|-----------|------------|--------|
| **Learning curve** | Medium | Steep | Easy |
| **Built-in registry** | ✅ | ❌ | N/A |
| **Web console** | ✅ Rich | Basic | N/A |
| **CI/CD** | ✅ Built-in | Requires tools | ❌ |
| **Security** | ✅ Enterprise | DIY | Basic |
| **Free tier** | ✅ Sandbox | ✅ Minikube | ✅ Desktop |
| **Production ready** | ✅ Yes | ✅ Yes | ❌ No |

---

## ✅ Validation Checklist

After completing all labs, you should be able to:

- [ ] Deploy app from source code (Git)
- [ ] Deploy app from container image
- [ ] Deploy database with Helm
- [ ] Create and use ConfigMaps
- [ ] Create and use Secrets
- [ ] Expose app via Routes
- [ ] View logs and debug pods
- [ ] Scale deployments
- [ ] Use `oc` CLI confidently

---

**Ready to start?** Go to https://developers.redhat.com/developer-sandbox and launch your free cluster! 🚀

**For offline learning:** See `C:\code\openshift-local-lab\` for full OpenShift Local installation guide (runs on your laptop, unlimited use).
