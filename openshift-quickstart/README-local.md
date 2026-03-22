# OpenShift Quick Start Guide (Local/CRC Edition)

**Time to complete: ~45 minutes | Cost: Free**

## 🎯 What You'll Learn

By the end of this guide, you'll understand:

- **OpenShift basics**: Enterprise Kubernetes platform from Red Hat
- **OpenShift Local (CRC)**: Running a local OpenShift cluster on your machine
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

### Lab 1: OpenShift Local Access (5 min)

**Goal:** Access your local OpenShift cluster

1. **Start OpenShift Local (if not already running):**

   ```powershell
   crc start
   ```
2. **Access web console:**

   - Open your browser to: `https://console-openshift-console.apps-crc.testing:7443`
   - *(Note: If you get redirected to `/auth/login` and see a connection error, click your browser's address bar and manually add `:7443` to the URL).*
   - Log in with username `developer` and password `developer`.
3. **Login via `oc` CLI:**

   ```powershell
   # Configure environment for oc
   & crc oc-env | Invoke-Expression

   # Login to the local API
   oc login -u developer -p developer https://api.crc.testing:6443

   #  If Login does not work, login to `https://console-openshift-console.apps-crc.testing:7443` via browser, go to developer-> Copy login command
   https://oauth-openshift.apps-crc.testing:7443/oauth/token/display
   ```

**Key takeaway:** OpenShift Local gives you a full OpenShift cluster running right on your machine!

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
   - *Remember to append `:8088` (for HTTP) or `:7443` (for HTTPS) to the URL in your browser if it's missing!*

**Via CLI:**

```powershell
# Create project
oc new-project hello-openshift

# Deploy from Git
oc new-app https://github.com/sclorg/nodejs-ex.git --name=nodejs-sample

# Expose route
oc expose svc/nodejs-sample

# Get URL (Add :8088 to the end of this host when visiting it!)
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

   # 1. Grant the 'anyuid' SCC to the default service account so Nginx can run as root, , as 'kubeadmin'
   oc adm policy add-scc-to-user anyuid -z default

   # 2. Restart the deployment to spin up a new pod with the new permissions
   oc rollout restart deployment/my-nginx

   # Expose route
   oc expose svc/my-nginx --port=80

   # Get route
   oc get route my-nginx
   ```
3. **Test the app:**

   ```powershell
   # Get URL
   $route = oc get route my-nginx -o jsonpath='{.spec.host}'

   # Open in browser or curl (Note the custom 8088 port for HTTP!)
   curl "http://${route}:8088"
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
   helm install my-postgres bitnami/postgresql `
     --set auth.postgresPassword=admin123 `
     --set auth.database=testdb `
     --set primary.persistence.size=1Gi
   ```
5. **Check deployment:**

   ```powershell
   # Wait for pod to be ready
   oc get pods -w
   # Press Ctrl+C when Running

   # Get service
   oc get svc

   # Notice that databases use StatefulSets instead of Deployments!
   oc get statefulsets
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
   oc create configmap app-config `
     --from-literal=APP_NAME="OpenShift Quick Start" `
     --from-literal=ENVIRONMENT="local"

   # View ConfigMap
   oc get configmap app-config -o yaml
   ```
2. **Create Secret:**

   ```powershell
   oc create secret generic db-credentials `
     --from-literal=username=admin `
     --from-literal=password=secret123

   # View (values are base64 encoded)
   oc get secret db-credentials -o yaml
   ```
3. **Deploy app with environment variables:**

   ```powershell
   # Create deployment
   oc create deployment env-demo --image=nginx:alpine

   # Grant the 'anyuid' SCC so Nginx can run as root in this new namespace, as 'kubeadmin'
   oc adm policy add-scc-to-user anyuid -z default
   oc rollout restart deployment/env-demo

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

## 🚨 Local Custom Port Reminder

If you ever encounter "Hmm... can't reach this page" when navigating OpenShift Local routes, remember that we are using custom ports for this local setup:

- **HTTP**: `8088` (Append `:8088` to `http://...` routes)
- **HTTPS**: `7443` (Append `:7443` to `https://...` routes)

This includes instances where the web console's internal routing accidentally redirects you back to the default port (like during login). Always add the port back into the address bar to continue.

---

## ✅ Validation Checklist

After completing all labs, you should be able to:

- [ ] Connect locally to OpenShift using `crc` and `oc login`
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

**Happy Learning!** 🚀
