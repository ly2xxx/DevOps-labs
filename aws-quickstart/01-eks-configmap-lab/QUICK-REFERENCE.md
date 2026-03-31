# ConfigMap Quick Reference

**Print this for your desk!**

---

## Create ConfigMap

```bash
# From literal values
kubectl create configmap my-config \
  --from-literal=key1=value1 \
  --from-literal=key2=value2

# From file
kubectl create configmap my-config \
  --from-file=config.txt

# From YAML
kubectl apply -f configmap.yaml
```

---

## View ConfigMap

```bash
# List all
kubectl get configmaps
kubectl get cm  # shorthand

# Show content
kubectl describe configmap my-config
kubectl get configmap my-config -o yaml

# Get specific key
kubectl get configmap my-config -o jsonpath='{.data.key1}'
```

---

## Edit ConfigMap

```bash
# Interactive edit (vi/nano)
kubectl edit configmap my-config

# Patch single value
kubectl patch configmap my-config \
  -p '{"data":{"key1":"newvalue"}}'

# Apply updated YAML
kubectl apply -f configmap.yaml
```

---

## Use in Pod - Environment Variables

```yaml
env:
- name: MY_VAR
  valueFrom:
    configMapKeyRef:
      name: my-config
      key: key1

# OR import all keys
envFrom:
- configMapRef:
    name: my-config
```

⚠️ **Requires pod restart to pick up changes!**

---

## Use in Pod - Volume Mount

```yaml
volumes:
- name: config
  configMap:
    name: my-config

volumeMounts:
- name: config
  mountPath: /etc/config
  readOnly: true
```

✅ **Auto-updates in ~60 seconds** (no restart needed)

---

## Restart Deployment

```bash
# Recommended: Rolling restart
kubectl rollout restart deployment my-app

# Alternative: Delete pods
kubectl delete pods -l app=my-app

# Alternative: Scale down/up
kubectl scale deployment my-app --replicas=0
kubectl scale deployment my-app --replicas=3
```

---

## Common Patterns

**Database URL:**
```yaml
data:
  DB_URL: "postgres://host:5432/db"
```

**JSON config file:**
```yaml
data:
  config.json: |
    {
      "setting1": "value1",
      "setting2": "value2"
    }
```

**Nginx config:**
```yaml
data:
  nginx.conf: |
    server {
      listen 80;
      server_name localhost;
    }
```

---

## Troubleshooting

**ConfigMap not found:**
```bash
kubectl get configmap  # Check if exists
kubectl describe pod <pod>  # Check errors
```

**Changes not applied:**
```bash
# Verify ConfigMap updated
kubectl get configmap my-config -o yaml

# Restart pods
kubectl rollout restart deployment my-app
```

**Volume not updating:**
```bash
# Wait 60-90 seconds
sleep 90

# Check if app re-reads file
kubectl logs <pod>
```

---

## Environment vs Volume

| Feature | Env Vars | Volume |
|---------|----------|--------|
| **Simple config** | ✅ Better | ❌ Overkill |
| **Config files** | ❌ Complex | ✅ Better |
| **Auto-update** | ❌ No (restart needed) | ✅ Yes (~60s) |
| **Large data** | ❌ Limited | ✅ Better |
| **Binary data** | ❌ No | ✅ Yes |

---

## Best Practices

✅ **DO:**
- Use ConfigMaps for non-sensitive config
- Version ConfigMaps (my-config-v1, my-config-v2)
- Document what each key does
- Test changes in dev first

❌ **DON'T:**
- Store passwords in ConfigMaps (use Secrets!)
- Make ConfigMaps too large (>1MB)
- Edit production ConfigMaps without backup
- Forget to restart pods after env var changes

---

## One-Liners

```bash
# Create from env file
kubectl create cm my-config --from-env-file=.env

# Export ConfigMap to file
kubectl get cm my-config -o yaml > backup.yaml

# Delete ConfigMap
kubectl delete configmap my-config

# Copy ConfigMap to another namespace
kubectl get cm my-config -o yaml | \
  sed 's/namespace: .*/namespace: new-ns/' | \
  kubectl apply -f -
```

---

**Remember:**
- ConfigMaps = Non-sensitive config
- Secrets = Sensitive data (passwords, keys)
- Env vars = Restart required
- Volumes = Auto-update

---

**For full lab:** See `README.md`
