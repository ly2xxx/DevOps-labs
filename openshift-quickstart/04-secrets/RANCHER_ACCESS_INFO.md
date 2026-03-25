# 🔐 Rancher Access Information

**Date:** 2026-03-05  
**Container:** rancher  
**Status:** ✅ Running

---

## 🌐 Access URL

**Rancher UI:** https://localhost:8443

---

## 👤 Admin Credentials

**Username:** `admin`

**Password:** `tSULfp897IDj3JC6Y89n`

**User ID:** `user-m2rgq`

---

## 🚀 First Login Steps

1. **Open browser:** https://localhost:8443

2. **Accept self-signed certificate:**
   - Chrome/Edge: Click "Advanced" → "Proceed to localhost (unsafe)"
   - Firefox: Click "Advanced" → "Accept the Risk and Continue"

3. **Log in:**
   - Username: `admin`
   - Password: `tSULfp897IDj3JC6Y89n`

4. **Initial Setup:**
   - Accept the Rancher EULA
   - Choose "I don't want Rancher to collect data" (recommended)
   - Set server URL (default is fine): `https://localhost:8443`
   - Click "Continue"

5. **You're in!** 🎉

---

## 🔄 Container Management

### Check status
```powershell
docker ps --filter name=rancher
```

### View logs
```powershell
docker logs rancher
```

### Restart container
```powershell
docker restart rancher
```

### Stop container
```powershell
docker stop rancher
```

### Start container
```powershell
docker start rancher
```

### Remove container (destructive!)
```powershell
docker stop rancher
docker rm rancher
```

---

## 💾 Data Persistence

**Important:** Rancher data is stored inside the container.

**To preserve data permanently:**
- Don't use `docker rm rancher` unless you want to start fresh
- Use `docker stop` / `docker start` for restarts
- For production, use volumes: `-v rancher-data:/var/lib/rancher`

**Current setup:** Data will persist between stops/starts, but will be lost if container is removed.

---

## 📊 Resource Limits

**Current configuration:**
- Memory: 3 GB
- CPUs: 1 core

**To check resource usage:**
```powershell
docker stats rancher --no-stream
```

**To adjust limits (requires recreation):**
```powershell
docker stop rancher
docker rm rancher

# Re-create with new limits
docker run -d --restart=unless-stopped `
  -p 8443:443 `
  --name rancher `
  --memory="4g" --cpus="2" `
  --privileged `
  rancher/rancher:latest
```

---

## 🆘 Troubleshooting

### Can't access UI

**Check container is running:**
```powershell
docker ps --filter name=rancher
```

**If not running, start it:**
```powershell
docker start rancher
```

### Forgot password

**Reset password:**
```powershell
docker exec rancher reset-password
```

### Port conflict (8443 in use)

**Use different port:**
```powershell
docker stop rancher
docker rm rancher

# Use port 9443 instead
docker run -d --restart=unless-stopped `
  -p 9443:443 `
  --name rancher `
  --memory="3g" --cpus="1" `
  --privileged `
  rancher/rancher:latest
```

Then access at: https://localhost:9443

### Slow performance

**Increase resource limits** (see above)

Or **reduce load:**
- Don't import multiple clusters simultaneously
- Close other heavy applications

---

## 📚 Next Steps

1. ✅ **Log into Rancher UI** (https://localhost:8443)
2. ⏳ **Explore the dashboard**
3. ⏳ **Watch tutorial video:** https://www.youtube.com/watch?v=oRLaD2k0IOI
4. ⏳ **Read:** `RANCHER_INTEGRATION.md` for full guide
5. ⏳ **Import a cluster** (cloud or local)

---

## 🔗 Resources

- **Rancher Docs:** https://ranchermanager.docs.rancher.com/
- **Getting Started:** https://ranchermanager.docs.rancher.com/getting-started/overview
- **Community:** https://slack.rancher.io/

---

**Rancher is ready! 🎉**

---

**Created:** 2026-03-05 12:16 GMT  
**Location:** C:\code\okd\RANCHER_ACCESS_INFO.md
