# OpenShift Quick Start - Start Here! 🚀

**Welcome to the OpenShift Quick Start guide!** This directory contains everything you need to get hands-on with OpenShift in ~45 minutes.

---

## 📖 What's in This Guide?

| File | Purpose | Time |
|------|---------|------|
| **PREFLIGHT.md** | Setup checklist - read this FIRST! | 5-10 min |
| **README.md** | Main tutorial with 5 hands-on labs | 45 min |
| **cheatsheet.md** | Essential commands reference | Always handy! |
| **examples/** | Sample YAML files to deploy | Copy-paste ready |

---

## 🚦 Quick Decision Tree

**New to OpenShift?**
1. ✅ Read **PREFLIGHT.md** first (setup)
2. ✅ Follow **README.md** labs 1-5
3. ✅ Keep **cheatsheet.md** open for reference

**Already have OpenShift access?**
- Skip PREFLIGHT.md
- Jump to README.md → Lab 2
- Use `examples/` for quick deployments

**Just need commands?**
- Go straight to **cheatsheet.md**

---

## ⚡ Fastest Path to Running App

**If you want to deploy something RIGHT NOW** (5 minutes):

### Option A: Developer Sandbox (Cloud)
```powershell
# 1. Sign up (no install): https://developers.redhat.com/developer-sandbox
# 2. Login to web console
# 3. Click "+Add" → "Import from Git"
# 4. Paste: https://github.com/sclorg/nodejs-ex.git
# 5. Click "Create"
# 6. Wait 2 min, click the route icon → App is live!
```

### Option B: Using `oc` CLI (After PREFLIGHT setup)
```powershell
# Login
oc login --token=<token> --server=<server>

# Create project
oc new-project hello-app

# Deploy from Git
oc new-app https://github.com/sclorg/nodejs-ex.git

# Expose
oc expose svc/nodejs-ex

# Get URL
oc get route nodejs-ex
```

**That's it!** You just deployed an app on OpenShift.

---

## 🎓 Learning Path

### Absolute Beginner (No Kubernetes/Docker experience)
1. **Read**: README.md introduction (10 min)
2. **Do**: Lab 1-2 (deploy from source) (15 min)
3. **Practice**: Lab 3 (deploy from image) (10 min)
4. **Reference**: Save cheatsheet.md

**Total:** ~35 minutes to first productive use

---

### Some Kubernetes Experience
1. **Skim**: README.md key differences (5 min)
2. **Do**: All labs 1-5 (30 min)
3. **Review**: `examples/` folder YAML files
4. **Compare**: OpenShift Routes vs K8s Ingress

**Total:** ~35 minutes to understand OpenShift additions

---

### Docker/Compose User Transitioning
1. **Read**: README.md "Big Picture" (5 min)
2. **Do**: Lab 2-3 (similar to `docker run`) (15 min)
3. **Do**: Lab 4 (Helm = Docker Compose++) (15 min)
4. **Compare**: See table below

**Total:** ~35 minutes to map Docker concepts

---

## 🔄 Docker → OpenShift Translation

For Docker/Compose users, here's the mental model:

| Docker Concept | OpenShift Equivalent |
|----------------|----------------------|
| `docker run` | `oc new-app` |
| `docker build` | `oc new-build` + `oc start-build` |
| `docker ps` | `oc get pods` |
| `docker logs` | `oc logs` |
| `docker exec` | `oc exec` |
| `docker-compose up` | `oc apply -f` or Helm |
| `docker-compose.yml` | Kubernetes YAML or Helm chart |
| Port mapping (`-p 8080:80`) | Service + Route |
| Volume (`-v`) | PersistentVolumeClaim |
| Environment (`-e`) | ConfigMap + Secret |

**Key difference:** OpenShift/K8s is declarative (describe desired state) vs Docker imperative (run commands).

---

## 🆚 Kubernetes → OpenShift Differences

For Kubernetes users:

| Kubernetes | OpenShift | Why OpenShift Adds It |
|------------|-----------|----------------------|
| Ingress | **Route** | Simpler, auto-SSL |
| Namespace | **Project** | + RBAC + Quotas |
| `kubectl` | **`oc`** | Same commands + extras |
| No built-in registry | **Built-in registry** | Easier image management |
| Manual CI/CD | **BuildConfig** + Pipelines | Integrated builds |
| Basic UI | **Rich developer UI** | Developer-focused |
| DIY security | **Security Context Constraints** | Enterprise security |

**Bottom line:** OpenShift = Kubernetes + batteries included.

---

## 📁 File Guide

### PREFLIGHT.md
**What:** Setup instructions and system requirements  
**When to read:** Before starting labs  
**You'll need:** 
- Red Hat account (free)
- `oc` CLI installed
- Either: Cloud sandbox access OR laptop with 16GB RAM

---

### README.md
**What:** Main tutorial with 5 hands-on labs  
**Labs included:**
1. Setup Developer Sandbox (5 min)
2. Deploy from source code (10 min)
3. Deploy from container image (10 min)
4. Deploy with Helm (15 min)
5. Use ConfigMaps & Secrets (5 min)

**Total time:** 45 minutes

---

### cheatsheet.md
**What:** Essential `oc` commands  
**Sections:**
- Login & auth
- Projects
- Deployments
- Routes
- Logs & debugging
- Configuration
- Builds
- Resource limits
- Troubleshooting

**Use:** Keep open in second window while learning

---

### examples/
**What:** Ready-to-use YAML files  
**Includes:**
- `simple-deployment.yaml` - NGINX with service + route
- `app-with-config.yaml` - Complete app with ConfigMap, Secret, HPA

**Usage:**
```powershell
oc apply -f examples/simple-deployment.yaml
oc get all
oc get route
```

---

## 💡 Pro Tips

### Tip 1: Use Both Sandbox and Local
- **Sandbox** (cloud): Quick experiments, demos, testing
- **Local** (laptop): Deep learning, offline work, longer-term projects

### Tip 2: Start with Web Console
- **First time:** Use web console to understand concepts
- **Once comfortable:** Switch to `oc` CLI for speed
- **Reference:** Keep cheatsheet.md handy

### Tip 3: Learn by Breaking
- OpenShift Sandbox is free and resets
- Delete and recreate projects freely
- Experiment with different deployment methods

### Tip 4: Copy Login Command
Web console → User icon → "Copy login command" → Paste in terminal

### Tip 5: Watch Resources
```powershell
# Live updates
oc get pods -w
oc get all -w

# Press Ctrl+C to stop watching
```

---

## 🚨 Common First-Time Gotchas

**1. "oc: command not found"**
- Solution: Install OpenShift CLI (see PREFLIGHT.md)
- Windows: Add to PATH or use full path

**2. "Error from server: User cannot create resource"**
- Solution: Check you're in the right project
- Run: `oc project my-project-name`

**3. "Pod is CrashLoopBackOff"**
- Solution: Check logs
- Run: `oc logs <pod-name>`
- Common cause: Wrong image or bad config

**4. "Can't access route"**
- Solution: Wait for pod to be Running
- Check: `oc get pods` (should show 1/1 Running)
- Then: `oc get route` and use that URL

**5. "Sandbox expired"**
- Solution: Reactivate for another 30 days (unlimited times)
- Go to: https://developers.redhat.com/developer-sandbox

---

## 🎯 What You'll Accomplish

After completing this guide:

✅ Deploy apps from source code (Git)  
✅ Deploy apps from container images  
✅ Use Helm charts  
✅ Configure apps with ConfigMaps/Secrets  
✅ Expose apps via Routes  
✅ View logs and debug issues  
✅ Scale applications  
✅ Understand OpenShift vs Kubernetes  

**Next steps:** Explore Operators, Pipelines, Service Mesh!

---

## 📞 Need Help?

**Stuck?** Check in this order:
1. README.md → Troubleshooting section
2. cheatsheet.md → Common commands
3. PREFLIGHT.md → Setup validation
4. OpenShift docs: https://docs.openshift.com/

**Official resources:**
- Learning: https://learn.openshift.com/
- Developer: https://developers.redhat.com/
- Community: https://www.openshift.com/community

---

## ⏱️ Time Estimates

| Activity | Time |
|----------|------|
| **Read START-HERE.md** (this file) | 5 min |
| **Complete PREFLIGHT.md** (setup) | 10-45 min* |
| **Complete README.md** (all labs) | 45 min |
| **Review examples/** | 10 min |
| **Reference cheatsheet.md** | Ongoing |

\* 10 min for Sandbox, 45 min for Local installation

**Total for complete tutorial:** ~1.5-2 hours (including setup)

---

## 🚀 Ready? Let's Go!

**Step 1:** Read **[PREFLIGHT.md](PREFLIGHT.md)** (setup)  
**Step 2:** Follow **[README.md](README.md)** (labs)  
**Step 3:** Bookmark **[cheatsheet.md](cheatsheet.md)** (reference)  

**Enjoy your OpenShift journey!** 🎉

---

**Created:** 2026-03-21  
**For:** Master Yang's DevOps lab collection  
**Maintained in:** `C:\code\DevOps-labs\openshift-quickstart\`
