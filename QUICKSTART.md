# Docker Quick Start - 15 Minutes to UBI9-Minimal Mastery

**Get hands-on with UBI9-minimal Coder templates in 15 minutes!**

---

## ✅ Prerequisites

```powershell
# Verify Docker is installed
docker --version
docker info

# Should see Docker version info
# If not, install Docker Desktop first
```

---

## 🚀 Step 1: Navigate to Project (30 seconds)

```powershell
cd C:\code\DevOps-labs\ubi9-minimal-coder
```

---

## 📦 Step 2: Build Basic Image (3 minutes)

```powershell
# Build UBI9-minimal with Python
docker build -t coder-template:ubi9-basic -f Dockerfile .
```

**What's happening:**
- Downloads UBI9-minimal base image (~100MB)
- Installs Python 3.11
- Creates non-root 'coder' user
- Sets up working directory

**Expected output:** "Successfully tagged coder-template:ubi9-basic"

---

## 🔍 Step 3: Check Image Size (30 seconds)

```powershell
docker images | findstr coder-template
```

**Expected result:**
```
coder-template   ubi9-basic   ...   ~150MB   ...
```

**Compare to typical UBI8:** ~380MB  
**Reduction:** ~60% smaller! 💾

---

## 🧪 Step 4: Test the Container (2 minutes)

```powershell
# Run container interactively
docker run -it --rm coder-template:ubi9-basic
```

**Inside container, try:**
```bash
# Check Python version
python3 --version        # Should be 3.11+

# Verify non-root user
whoami                   # Should show: coder

# Check working directory
pwd                      # Should show: /home/coder

# Verify pip is available
pip --version            # Should work

# Exit container
exit
```

---

## 🏗️ Step 5: Build Optimized Version (3 minutes)

```powershell
# Build multi-stage optimized image
docker build -t coder-template:ubi9-optimized -f Dockerfile.optimized .
```

**What's different:**
- Multi-stage build (builder + runtime)
- Packages pre-installed (no pip in final image)
- Smallest possible size (~130MB)

---

## 📊 Step 6: Compare All Versions (3 minutes)

```powershell
# Build all three versions
.\build-all.ps1

# Compare sizes
.\compare-images.ps1
```

**You'll see:**
- **Basic:** ~150MB (Python + pip, easy to customize)
- **Optimized:** ~130MB (ultra-minimal, production-ready)
- **Claude:** ~180MB (Claude Code pre-installed)

---

## 🧪 Step 7: Run Automated Tests (2 minutes)

```powershell
# Test basic version
.\test-container.ps1 -Version basic

# Test optimized version
.\test-container.ps1 -Version optimized

# Test Claude Code version
.\test-container.ps1 -Version claude
```

**Tests verify:**
- ✅ Python 3.11+ installed
- ✅ Running as non-root user
- ✅ Correct working directory
- ✅ Shell access works
- ✅ Environment variables set

---

## 🎯 Step 8: Simulate Coder Console (1 minute)

```powershell
# Start container in background
docker run -d --name test-coder coder-template:ubi9-basic

# Attach to console (like Coder platform)
docker exec -it test-coder /bin/bash
```

**Inside container:**
```bash
# This simulates Coder console access
# Try installing a package
pip install --user requests

# Verify installation
python3 -c "import requests; print('Works!')"

# Exit
exit
```

**Cleanup:**
```powershell
docker stop test-coder
docker rm test-coder
```

---

## ✅ Success! You've Learned:

- [x] How to build UBI9-minimal images
- [x] Multi-stage builds for optimization
- [x] Image size comparison (60% reduction!)
- [x] Running containers interactively
- [x] Testing container functionality
- [x] Simulating Coder console access

---

## 📚 Next Steps

### 1. **Customize for Your Use Case**

Edit `Dockerfile` to add packages:
```dockerfile
RUN microdnf install -y \
    python3.11 \
    python3.11-pip \
    git \              # Add git
    && microdnf clean all
```

Rebuild:
```powershell
docker build -t coder-template:custom -f Dockerfile .
```

---

### 2. **Study the Dockerfiles**

Compare all three versions:
```powershell
# Open in VSCode
code Dockerfile
code Dockerfile.optimized
code Dockerfile.with-claude-code
```

**Key differences:**
- **Basic:** Simple, includes pip
- **Optimized:** Multi-stage, no pip in final image
- **Claude:** Pre-installed Claude Code packages

---

### 3. **Read Full Documentation**

- [Main README](README.md) - Comprehensive Docker guide
- [UBI9-Minimal README](ubi9-minimal-coder/README.md) - Case study details
- [CHEATSHEET](CHEATSHEET.md) - Quick command reference

---

### 4. **Deploy to Coder Platform**

```powershell
# Tag for registry
docker tag coder-template:ubi9-optimized barclays-registry.io/coder-templates/ubi9-python:1.0

# Push (if you have access)
docker push barclays-registry.io/coder-templates/ubi9-python:1.0
```

See `coder-template.yaml` for Coder platform configuration.

---

## 🎓 Quick Reference

### Build Commands
```powershell
# Basic version
docker build -t coder-template:ubi9-basic -f Dockerfile .

# Optimized version
docker build -t coder-template:ubi9-optimized -f Dockerfile.optimized .

# Claude Code version
docker build -t coder-template:ubi9-claude -f Dockerfile.with-claude-code .

# All versions at once
.\build-all.ps1
```

### Run Commands
```powershell
# Interactive (shell access)
docker run -it --rm coder-template:ubi9-basic

# Background (detached)
docker run -d --name mycontainer coder-template:ubi9-basic

# Execute command
docker run --rm coder-template:ubi9-basic python3 --version
```

### Management Commands
```powershell
# List images
docker images | findstr coder-template

# List containers
docker ps

# View logs
docker logs <container-id>

# Stop container
docker stop <container-id>

# Remove container
docker rm <container-id>

# Remove image
docker rmi coder-template:ubi9-basic
```

---

## ❓ Troubleshooting

**"Cannot connect to Docker daemon"**
- Ensure Docker Desktop is running
- Check system tray for Docker icon

**"Image not found"**
- Did you build it first?
- Check: `docker images`

**"Permission denied"**
- You're running as 'coder' user (non-root)
- This is expected and secure!

**Build is slow**
- First build downloads base image (~100MB)
- Subsequent builds use cache (much faster)

**Image size larger than expected**
- Check: `docker history coder-template:ubi9-basic`
- Make sure you're cleaning packages: `microdnf clean all`

---

## 🎯 Challenge Yourself

**Easy:** Add `git` to the basic Dockerfile and rebuild  
**Medium:** Create a custom version with additional Python packages  
**Hard:** Optimize the image to <120MB using multi-stage build

---

## 📊 Your Results

After completing this guide:

**Time invested:** 15 minutes  
**Images built:** 3 variants  
**Size reduction learned:** 60%+ vs UBI8  
**Skills gained:** Docker basics + optimization + security

**Ready for production?** Share with William Burton for DevSecOps review!

---

**Questions? Check the main [README.md](README.md) or [CHEATSHEET.md](CHEATSHEET.md)!**

🎉 **Congratulations! You've mastered UBI9-minimal containers!** 🐳
