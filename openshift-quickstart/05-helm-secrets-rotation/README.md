# Helm Deployments with Secret Rotation Lab

**Focus Areas:**
- ✅ Helm chart deployment patterns
- ✅ Secret rotation without pod redeployment
- ✅ ConfigMap and Secret management strategies
- ✅ Rolling updates and zero-downtime changes

**Complexity:** Intermediate  
**Time:** 1-2 hours  
**Prerequisites:** OKD cluster running (CRC)

---

## What You'll Learn

1. **Helm Basics**
   - Create custom Helm charts
   - Deploy applications with Helm
   - Manage releases and rollbacks

2. **Secret Management Patterns**
   - Kubernetes Secrets vs ConfigMaps
   - Hot-reload secrets without restart
   - Secret rotation strategies

3. **Production Patterns**
   - Zero-downtime deployments
   - Rolling updates with secret changes
   - Health checks and readiness probes

---

## Lab Architecture

```
┌─────────────────────────────────────────────────────┐
│              OKD Cluster (CRC)                      │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Namespace: helm-secrets-lab                 │  │
│  │                                              │  │
│  │  ┌──────────────┐      ┌──────────────┐    │  │
│  │  │  App v1      │      │  Secret v1   │    │  │
│  │  │  (3 pods)    │◄─────┤  (mounted)   │    │  │
│  │  └──────────────┘      └──────────────┘    │  │
│  │         │                                   │  │
│  │         │ Rolling Update (secret rotation)  │  │
│  │         ▼                                   │  │
│  │  ┌──────────────┐      ┌──────────────┐    │  │
│  │  │  App v2      │      │  Secret v2   │    │  │
│  │  │  (3 pods)    │◄─────┤  (new value) │    │  │
│  │  └──────────────┘      └──────────────┘    │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## Part 1: Create a Custom Helm Chart

### Step 1.1: Setup Project Structure

```powershell
# Create project directory
New-Item -ItemType Directory -Path C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation\my-app-chart -Force

cd C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation\my-app-chart

# Create Helm chart structure
helm create my-app
```

### Step 1.2: Customize Chart Templates

**Edit `my-app/values.yaml`:**

```yaml
replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25-alpine"

service:
  type: ClusterIP
  port: 80

# Secret configuration
secrets:
  databasePassword: "initial_password_123"
  apiKey: "api_key_v1_xyz"
  jwtSecret: "jwt_secret_initial"

# ConfigMap configuration
config:
  appName: "My Awesome App"
  environment: "development"
  logLevel: "info"
  features:
    enableMetrics: "true"
    enableDebug: "false"

# Rolling update strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0

# Health checks
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5

# Resource limits
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

**Edit `my-app/templates/deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  strategy:
    {{- toYaml .Values.strategy | nindent 4 }}
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        # Force pod restart on config/secret change
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        
        # Environment variables from ConfigMap
        envFrom:
        - configMapRef:
            name: {{ include "my-app.fullname" . }}-config
        
        # Sensitive environment variables from Secret
        env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "my-app.fullname" . }}-secret
              key: databasePassword
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: {{ include "my-app.fullname" . }}-secret
              key: apiKey
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: {{ include "my-app.fullname" . }}-secret
              key: jwtSecret
        
        # Mount secrets as files (alternative approach)
        volumeMounts:
        - name: secret-files
          mountPath: /etc/secrets
          readOnly: true
        - name: config-files
          mountPath: /etc/config
          readOnly: true
        
        {{- with .Values.livenessProbe }}
        livenessProbe:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        
        {{- with .Values.readinessProbe }}
        readinessProbe:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
      
      volumes:
      - name: secret-files
        secret:
          secretName: {{ include "my-app.fullname" . }}-secret
      - name: config-files
        configMap:
          name: {{ include "my-app.fullname" . }}-config
```

**Create `my-app/templates/configmap.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-app.fullname" . }}-config
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
data:
  APP_NAME: {{ .Values.config.appName | quote }}
  ENVIRONMENT: {{ .Values.config.environment | quote }}
  LOG_LEVEL: {{ .Values.config.logLevel | quote }}
  ENABLE_METRICS: {{ .Values.config.features.enableMetrics | quote }}
  ENABLE_DEBUG: {{ .Values.config.features.enableDebug | quote }}
  
  # Config file example
  app-config.json: |
    {
      "appName": "{{ .Values.config.appName }}",
      "environment": "{{ .Values.config.environment }}",
      "logLevel": "{{ .Values.config.logLevel }}",
      "features": {
        "enableMetrics": {{ .Values.config.features.enableMetrics }},
        "enableDebug": {{ .Values.config.features.enableDebug }}
      }
    }
```

**Create `my-app/templates/secret.yaml`:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-app.fullname" . }}-secret
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
type: Opaque
stringData:
  databasePassword: {{ .Values.secrets.databasePassword | quote }}
  apiKey: {{ .Values.secrets.apiKey | quote }}
  jwtSecret: {{ .Values.secrets.jwtSecret | quote }}
  
  # Secret file example
  database-credentials.json: |
    {
      "host": "postgres.example.com",
      "port": 5432,
      "username": "app_user",
      "password": "{{ .Values.secrets.databasePassword }}"
    }
```

---

## Part 2: Deploy with Helm

### Step 2.1: Login to OKD

```powershell
# Start CRC if not running
crc start

# Login as developer
oc login -u developer https://api.crc.testing:6443

# Create project
oc new-project helm-secrets-lab
```

### Step 2.2: Install Helm Chart

```powershell
cd C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation\my-app-chart

# Install the chart
helm install my-app ./my-app -n helm-secrets-lab

# Check deployment status
helm list -n helm-secrets-lab
oc get pods -n helm-secrets-lab
oc get all -n helm-secrets-lab
```

### Step 2.3: Verify Deployment

```powershell
# Get pod name
$POD = oc get pod -n helm-secrets-lab -l app.kubernetes.io/name=my-app -o jsonpath='{.items[0].metadata.name}'

# Check environment variables
oc exec -n helm-secrets-lab $POD -- env | Select-String -Pattern "DATABASE|API|JWT|APP_NAME|ENVIRONMENT"

# Check mounted secret files
oc exec -n helm-secrets-lab $POD -- cat /etc/secrets/databasePassword
oc exec -n helm-secrets-lab $POD -- cat /etc/secrets/database-credentials.json

# Check mounted config files
oc exec -n helm-secrets-lab $POD -- cat /etc/config/app-config.json
```

---

## Part 3: Secret Rotation Strategies

### Strategy 1: Rolling Update with Checksum Annotation (Automatic Restart)

This is already configured in our deployment template with these annotations:

```yaml
annotations:
  checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
  checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
```

**How it works:**
- When secrets/config change, the checksum changes
- Kubernetes detects annotation change → triggers rolling update
- Pods restart with new secrets automatically

**Test it:**

```powershell
# Update secret value in values.yaml
# Edit: C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation\my-app-chart\my-app\values.yaml
# Change: databasePassword: "rotated_password_456"

# Upgrade the release
helm upgrade my-app ./my-app -n helm-secrets-lab

# Watch rolling update
oc get pods -n helm-secrets-lab -w

# Verify new secret
$POD = oc get pod -n helm-secrets-lab -l app.kubernetes.io/name=my-app -o jsonpath='{.items[0].metadata.name}'
oc exec -n helm-secrets-lab $POD -- cat /etc/secrets/databasePassword
```

### Strategy 2: Hot-Reload Secrets (No Restart Required)

For applications that can reload config at runtime.

**Create hot-reload enabled app:**

```yaml
# my-app/templates/deployment-hotreload.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}-hotreload
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: my-app-hotreload
    spec:
      containers:
      - name: config-reloader
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
          - |
            # Monitor config file changes
            while true; do
              inotifywait -e modify /etc/config/app-config.json 2>/dev/null && \
              echo "Config changed! Application should reload..."
              sleep 5
            done
        volumeMounts:
        - name: config-files
          mountPath: /etc/config
      
      volumes:
      - name: config-files
        configMap:
          name: {{ include "my-app.fullname" . }}-config
```

**Note:** Secrets mounted as volumes update automatically (with kubelet sync delay ~1 minute), but environment variables do NOT update without restart.

### Strategy 3: External Secrets with Version Tagging

```powershell
# Create versioned secrets
oc create secret generic my-app-secret-v1 --from-literal=password=pass_v1 -n helm-secrets-lab
oc create secret generic my-app-secret-v2 --from-literal=password=pass_v2 -n helm-secrets-lab

# Update deployment to reference new version (zero-downtime)
# Edit deployment to use my-app-secret-v2
helm upgrade my-app ./my-app \
  --set secrets.secretName=my-app-secret-v2 \
  -n helm-secrets-lab
```

### Strategy 4: Blue-Green Deployment for Secrets

```powershell
# Install "green" version with new secrets
helm install my-app-green ./my-app \
  -n helm-secrets-lab \
  --set secrets.databasePassword="green_password" \
  --set nameOverride="my-app-green"

# Test green deployment
oc get pods -n helm-secrets-lab -l app=my-app-green

# Switch traffic (update Service selector)
oc patch svc my-app -n helm-secrets-lab -p '{"spec":{"selector":{"app":"my-app-green"}}}'

# Remove old "blue" deployment
helm uninstall my-app -n helm-secrets-lab
```

---

## Part 4: Advanced Helm Patterns

### Pattern 1: Separate Secrets File (Security Best Practice)

**Create `secrets.yaml` (gitignored):**

```yaml
secrets:
  databasePassword: "production_password_XYZ"
  apiKey: "prod_api_key_ABC"
  jwtSecret: "prod_jwt_secret_DEF"
```

**Deploy with separate values:**

```powershell
helm install my-app ./my-app \
  -f my-app/values.yaml \
  -f secrets.yaml \
  -n helm-secrets-lab
```

**Add to `.gitignore`:**
```
secrets.yaml
*.secret.yaml
```

### Pattern 2: Environment-Specific Values

**Create value files:**
- `values-dev.yaml`
- `values-staging.yaml`
- `values-prod.yaml`

```powershell
# Deploy to dev
helm install my-app ./my-app -f values-dev.yaml -n dev

# Deploy to production
helm install my-app ./my-app -f values-prod.yaml -n production
```

### Pattern 3: Sealed Secrets (GitOps-Safe)

Install Sealed Secrets controller:

```powershell
# Install sealed-secrets controller
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system

# Install kubeseal CLI (Windows)
# Download from: https://github.com/bitnami-labs/sealed-secrets/releases

# Create a secret
oc create secret generic my-secret --from-literal=password=secret123 --dry-run=client -o yaml > secret.yaml

# Seal it
kubeseal -f secret.yaml -o yaml > sealed-secret.yaml

# Safe to commit sealed-secret.yaml to Git!
oc apply -f sealed-secret.yaml
```

---

## Part 5: Testing & Verification

### Test 1: Rolling Update with Zero Downtime

```powershell
# Terminal 1: Watch pods
oc get pods -n helm-secrets-lab -w

# Terminal 2: Continuous request loop
while ($true) {
  $ROUTE = oc get route my-app -n helm-secrets-lab -o jsonpath='{.spec.host}'
  curl "http://$ROUTE" -UseBasicParsing
  Start-Sleep -Seconds 1
}

# Terminal 3: Trigger rolling update
helm upgrade my-app ./my-app \
  --set secrets.databasePassword="new_password_789" \
  -n helm-secrets-lab
```

**Expected:** No 503 errors during update.

### Test 2: Secret Rotation Verification

```powershell
# Before rotation
$POD1 = oc get pod -n helm-secrets-lab -l app.kubernetes.io/name=my-app -o jsonpath='{.items[0].metadata.name}'
oc exec -n helm-secrets-lab $POD1 -- cat /etc/secrets/databasePassword

# Rotate secret
helm upgrade my-app ./my-app \
  --set secrets.databasePassword="rotated_$(Get-Random)" \
  -n helm-secrets-lab

# Wait for rollout
oc rollout status deployment/my-app -n helm-secrets-lab

# After rotation
$POD2 = oc get pod -n helm-secrets-lab -l app.kubernetes.io/name=my-app -o jsonpath='{.items[0].metadata.name}'
oc exec -n helm-secrets-lab $POD2 -- cat /etc/secrets/databasePassword

# Compare - should be different
```

### Test 3: Helm Rollback

```powershell
# List revisions
helm history my-app -n helm-secrets-lab

# Rollback to previous version
helm rollback my-app 1 -n helm-secrets-lab

# Verify rollback
oc get pods -n helm-secrets-lab
```

---

## Part 6: Production Checklist

### Security Best Practices

- [ ] Never commit secrets to Git
- [ ] Use separate values files for secrets (`.gitignore`d)
- [ ] Consider Sealed Secrets or external secret management
- [ ] Use RBAC to restrict secret access
- [ ] Enable audit logging for secret access
- [ ] Rotate secrets regularly (automated)
- [ ] Use short-lived tokens where possible

### Deployment Best Practices

- [ ] Always use rolling updates (not Recreate)
- [ ] Set `maxUnavailable: 0` for zero-downtime
- [ ] Add readiness probes (traffic only to ready pods)
- [ ] Add liveness probes (restart unhealthy pods)
- [ ] Use resource limits (prevent resource exhaustion)
- [ ] Test rollback procedures
- [ ] Monitor deployment progress
- [ ] Use Pod Disruption Budgets (PDB) for HA

### Helm Best Practices

- [ ] Pin chart versions in production
- [ ] Use Helm hooks for pre/post deployment tasks
- [ ] Document all values in `values.yaml` with comments
- [ ] Use `helm lint` and `helm template` before deployment
- [ ] Tag releases with meaningful versions
- [ ] Keep chart dependencies up to date
- [ ] Use Helm secrets plugin or similar for sensitive data

---

## Troubleshooting

### Issue: Pods Not Restarting After Secret Update

**Cause:** No checksum annotation or secret mounted as env var

**Solution:**
```yaml
# Add to deployment template metadata.annotations
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
```

### Issue: Old Secret Values Still Visible

**Cause:** Secret mounted as environment variable (doesn't auto-update)

**Solution:** Use volume mounts instead:
```yaml
volumeMounts:
- name: secret-files
  mountPath: /etc/secrets
volumes:
- name: secret-files
  secret:
    secretName: my-secret
```

### Issue: Helm Upgrade Fails with Validation Error

**Debugging:**
```powershell
# Dry run to see rendered templates
helm upgrade my-app ./my-app --dry-run --debug -n helm-secrets-lab

# Render templates locally
helm template my-app ./my-app > rendered.yaml

# Validate YAML
oc apply -f rendered.yaml --dry-run=client
```

---

## Cleanup

```powershell
# Uninstall Helm release
helm uninstall my-app -n helm-secrets-lab

# Delete namespace
oc delete project helm-secrets-lab

# Optional: Remove chart directory
Remove-Item -Recurse -Force C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation\my-app-chart
```

---

## Additional Resources

### Official Documentation
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)

### Tools
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [Helm Secrets Plugin](https://github.com/jkroepke/helm-secrets)
- [SOPS (Secrets OPerationS)](https://github.com/mozilla/sops)

### Tutorials
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Zero-Downtime Deployments](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)

---

## Summary

This lab covered:

✅ Creating custom Helm charts from scratch  
✅ Deploying applications with Helm to OKD  
✅ Managing Secrets and ConfigMaps  
✅ **4 Secret Rotation Strategies:**
  1. Automatic restart with checksum annotations
  2. Hot-reload with volume mounts
  3. Version tagging
  4. Blue-green deployments  
✅ Zero-downtime rolling updates  
✅ Production-ready patterns and security  

**Key Takeaway:** Secret rotation without downtime is achievable with proper Kubernetes deployment strategies and Helm templating.

---

**Created:** March 2026  
**Lab Environment:** OKD (CRC) on Windows  
**Focus:** Practical, production-ready patterns

---

Happy deploying! 🚀
