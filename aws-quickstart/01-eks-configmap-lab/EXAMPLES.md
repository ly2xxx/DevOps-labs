# Real-World ConfigMap Examples

---

## Example 1: Feature Flags

**Use case:** Toggle features without redeploying

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  new_ui: "true"
  beta_features: "false"
  dark_mode: "true"
  analytics: "false"
```

**Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        envFrom:
        - configMapRef:
            name: feature-flags
```

**Toggle feature:**
```bash
# Enable beta features
kubectl patch configmap feature-flags \
  -p '{"data":{"beta_features":"true"}}'

# Restart frontend
kubectl rollout restart deployment frontend
```

---

## Example 2: Multi-Environment Config

**Use case:** Same app, different configs for dev/staging/prod

**ConfigMap (Dev):**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: dev
data:
  DB_HOST: "dev-db.internal"
  LOG_LEVEL: "debug"
  CACHE_ENABLED: "false"
```

**ConfigMap (Prod):**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: prod
data:
  DB_HOST: "prod-db.internal"
  LOG_LEVEL: "error"
  CACHE_ENABLED: "true"
```

**Deployment (same for both namespaces):**
```yaml
spec:
  containers:
  - name: app
    envFrom:
    - configMapRef:
        name: app-config
```

Deploy to dev: `kubectl apply -f deployment.yaml -n dev`  
Deploy to prod: `kubectl apply -f deployment.yaml -n prod`

---

## Example 3: Application Configuration File

**Use case:** App reads JSON config file

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  application.json: |
    {
      "server": {
        "port": 8080,
        "host": "0.0.0.0"
      },
      "database": {
        "host": "postgres.default.svc.cluster.local",
        "port": 5432,
        "name": "myapp"
      },
      "logging": {
        "level": "info",
        "format": "json"
      }
    }
```

**Deployment:**
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    command: ["./app", "--config", "/config/application.json"]
    volumeMounts:
    - name: config
      mountPath: /config
  volumes:
  - name: config
    configMap:
      name: app-config
```

**Update config:**
```bash
# Edit ConfigMap
kubectl edit configmap app-config

# Wait 60s for volume to update
sleep 60

# If app watches file, it reloads automatically
# Otherwise, restart:
kubectl rollout restart deployment app
```

---

## Example 4: Nginx Configuration

**Use case:** Custom nginx.conf for frontend proxy

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    user nginx;
    worker_processes auto;
    
    events {
        worker_connections 1024;
    }
    
    http {
        upstream backend {
            server backend-service:8080;
        }
        
        server {
            listen 80;
            server_name myapp.example.com;
            
            location / {
                root /usr/share/nginx/html;
                try_files $uri $uri/ /index.html;
            }
            
            location /api {
                proxy_pass http://backend;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
            }
        }
    }
```

**Deployment:**
```yaml
spec:
  containers:
  - name: nginx
    image: nginx:latest
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: nginx-config
    configMap:
      name: nginx-config
```

**Update nginx config:**
```bash
kubectl edit configmap nginx-config
# After 60s, nginx reloads config automatically (with proper setup)
# Or force reload:
kubectl exec <nginx-pod> -- nginx -s reload
```

---

## Example 5: Database Connection Strings

**Use case:** Multiple services connecting to different databases

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: database-urls
data:
  PRIMARY_DB: "postgres://postgres.default:5432/main"
  ANALYTICS_DB: "postgres://analytics.default:5432/analytics"
  CACHE_URL: "redis://redis.default:6379/0"
  MONGO_URL: "mongodb://mongo.default:27017/app"
```

**Deployment (Backend):**
```yaml
spec:
  containers:
  - name: backend
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: database-urls
          key: PRIMARY_DB
    - name: REDIS_URL
      valueFrom:
        configMapKeyRef:
          name: database-urls
          key: CACHE_URL
```

**Deployment (Analytics):**
```yaml
spec:
  containers:
  - name: analytics
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: database-urls
          key: ANALYTICS_DB
```

---

## Example 6: Logging Configuration

**Use case:** Different log levels per environment

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logging-config
data:
  log4j2.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <Configuration status="WARN">
      <Appenders>
        <Console name="Console" target="SYSTEM_OUT">
          <PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>
        </Console>
      </Appenders>
      <Loggers>
        <Root level="info">
          <AppenderRef ref="Console"/>
        </Root>
        <Logger name="com.myapp" level="debug" additivity="false">
          <AppenderRef ref="Console"/>
        </Logger>
      </Loggers>
    </Configuration>
```

**Deployment:**
```yaml
spec:
  containers:
  - name: java-app
    volumeMounts:
    - name: logging-config
      mountPath: /app/config/log4j2.xml
      subPath: log4j2.xml
  volumes:
  - name: logging-config
    configMap:
      name: logging-config
```

---

## Example 7: API Keys & Endpoints (Non-Sensitive)

**Use case:** Third-party API endpoints

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  WEATHER_API_URL: "https://api.openweathermap.org/data/2.5"
  MAPS_API_URL: "https://maps.googleapis.com/maps/api"
  ANALYTICS_URL: "https://analytics.example.com/v1"
  # Note: API keys should go in Secrets, not ConfigMaps!
```

**Deployment:**
```yaml
spec:
  containers:
  - name: app
    envFrom:
    - configMapRef:
        name: api-config
    - secretRef:
        name: api-keys  # Secrets for sensitive data!
```

---

## Example 8: Blue-Green Deployment Toggle

**Use case:** Route traffic to blue or green version

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: routing-config
data:
  ACTIVE_VERSION: "blue"
  BLUE_WEIGHT: "100"
  GREEN_WEIGHT: "0"
```

**Deployment (Proxy):**
```yaml
spec:
  containers:
  - name: proxy
    env:
    - name: ACTIVE_VERSION
      valueFrom:
        configMapKeyRef:
          name: routing-config
          key: ACTIVE_VERSION
    - name: BLUE_WEIGHT
      valueFrom:
        configMapKeyRef:
          name: routing-config
          key: BLUE_WEIGHT
    - name: GREEN_WEIGHT
      valueFrom:
        configMapKeyRef:
          name: routing-config
          key: GREEN_WEIGHT
```

**Switch to green:**
```bash
kubectl patch configmap routing-config \
  -p '{"data":{"ACTIVE_VERSION":"green","BLUE_WEIGHT":"0","GREEN_WEIGHT":"100"}}'

kubectl rollout restart deployment proxy
```

---

## Example 9: Scheduled Jobs Configuration

**Use case:** CronJob with configurable schedule

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cronjob-config
data:
  SCHEDULE: "0 2 * * *"  # 2 AM daily
  BACKUP_PATH: "/backups"
  RETENTION_DAYS: "7"
```

**CronJob:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Defined separately
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            envFrom:
            - configMapRef:
                name: cronjob-config
```

---

## Example 10: Testing ConfigMap Changes

**ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-config
data:
  VERSION: "1.0"
  MESSAGE: "Hello from ConfigMap v1"
```

**Test pod:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test
    image: busybox
    command:
    - sh
    - -c
    - |
      while true; do
        echo "Version: $VERSION"
        echo "Message: $MESSAGE"
        echo "File message: $(cat /config/MESSAGE)"
        sleep 10
      done
    env:
    - name: VERSION
      valueFrom:
        configMapKeyRef:
          name: test-config
          key: VERSION
    - name: MESSAGE
      valueFrom:
        configMapKeyRef:
          name: test-config
          key: MESSAGE
    volumeMounts:
    - name: config
      mountPath: /config
  volumes:
  - name: config
    configMap:
      name: test-config
```

**Test the difference:**
```bash
# Deploy pod
kubectl apply -f test-pod.yaml

# Check logs (shows v1)
kubectl logs test-pod

# Update ConfigMap
kubectl patch configmap test-config \
  -p '{"data":{"MESSAGE":"Hello from ConfigMap v2"}}'

# Wait 10s, check logs again
# Env var MESSAGE: Still shows v1 (no restart yet)
# File MESSAGE: Shows v2 (after ~60s)

# Restart pod
kubectl delete pod test-pod
kubectl apply -f test-pod.yaml

# Now both show v2
kubectl logs test-pod
```

---

## Summary Table

| Example | Method | Auto-Update | Use Case |
|---------|--------|-------------|----------|
| Feature Flags | Env | ❌ | Toggle features |
| Multi-Env | Env | ❌ | Dev/Staging/Prod |
| App Config | Volume | ✅ | JSON/YAML files |
| Nginx Config | Volume | ✅ | Proxy config |
| DB URLs | Env | ❌ | Connection strings |
| Logging | Volume | ✅ | Log4j/logback |
| API Endpoints | Env | ❌ | Third-party APIs |
| Blue-Green | Env | ❌ | Traffic routing |
| CronJobs | Env | ❌ | Scheduled tasks |
| Testing | Both | Mixed | Compare methods |

---

**Remember:**
- **Environment variables** = Simple values, requires restart
- **Volumes** = Config files, auto-updates in ~60s
- **Secrets** = For passwords/keys, NOT ConfigMaps!

---

**For full lab:** See `README.md`
