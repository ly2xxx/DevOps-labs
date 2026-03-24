# DevOps Labs - Project Structure

Complete overview of the Docker learning lab focused on UBI9-minimal optimization.

---

## 📁 Directory Structure

```
C:\code\DevOps-labs\
│
├── README.md                      # Main tutorial (comprehensive Docker guide)
├── QUICKSTART.md                  # 15-minute hands-on guide
├── CHEATSHEET.md                  # Quick command reference
├── PROJECT_STRUCTURE.md           # This file
├── test-setup.ps1                 # Verify Docker installation
│
└── ubi9-minimal-coder/            # ⭐ Main use case: Minimal Coder template
    ├── README.md                  # Detailed case study documentation
    ├── Dockerfile                 # Basic UBI9-minimal + Python (~150MB)
    ├── Dockerfile.optimized       # Multi-stage ultra-minimal (~130MB)
    ├── Dockerfile.with-claude-code # Claude Code pre-installed (~180MB)
    ├── .dockerignore              # Build optimization
    ├── build-all.ps1              # Build all three versions
    ├── compare-images.ps1         # Size comparison tool
    ├── test-container.ps1         # Automated testing script
    ├── coder-template.yaml        # Example Coder platform config
    └── example-claude-skill.py    # Test Python script for Claude Code
```

---

## 🎯 Learning Path

### 1. **Absolute Beginners** (1-2 hours)
New to Docker? Start here.

**Path:**
1. Run `test-setup.ps1` to verify your environment
2. Read **QUICKSTART.md** (15-minute hands-on)
3. Build the basic UBI9-minimal image
4. Test it interactively
5. Keep **CHEATSHEET.md** handy

**You'll learn:**
- What Docker is and how it works
- How to build images from Dockerfiles
- How to run and manage containers
- Basic image size optimization

---

### 2. **Intermediate** (2-4 hours)
Comfortable with basics, want real-world skills?

**Path:**
1. Read **README.md** (comprehensive guide)
2. Study all three Dockerfiles in `ubi9-minimal-coder/`
3. Build and compare all variants
4. Run automated tests
5. Customize a Dockerfile for your use case

**You'll learn:**
- Multi-stage builds for optimization
- Security best practices (non-root, minimal base)
- UBI9 vs UBI8 comparison
- Production-ready patterns
- DevSecOps compliance

---

### 3. **Advanced** (4+ hours)
Ready to deploy to Barclays platform?

**Path:**
1. Complete intermediate level
2. Optimize image to <120MB
3. Test against Barclays security gates
4. Deploy to Coder platform
5. Share with William Burton for DevSecOps review

**You'll learn:**
- Advanced size optimization techniques
- Container security hardening
- Coder platform integration
- Registry management
- Production deployment workflows

---

## 📚 Document Guide

### **README.md** - Main Tutorial
**Purpose:** Comprehensive Docker learning with UBI9-minimal focus

**Contains:**
- Docker fundamentals (images, containers, Dockerfile)
- Essential commands and best practices
- UBI9-minimal vs UBI8 comparison
- Security and optimization techniques
- VSCode debugging setup

**Read when:**
- First time learning Docker
- Need detailed explanations
- Understanding Dockerfile instructions
- Preparing for production deployment

**Time:** 1-2 hours

---

### **QUICKSTART.md** - Hands-On Guide
**Purpose:** Get productive in 15 minutes with step-by-step instructions

**Contains:**
- 8-step walkthrough (build → test → optimize)
- Automated scripts usage
- Quick troubleshooting
- Next steps guidance

**Read when:**
- Want to dive in immediately
- Learn by doing
- Quick refresher needed
- Showing someone Docker fast

**Time:** 15-30 minutes

---

### **CHEATSHEET.md** - Command Reference
**Purpose:** Fast lookup for Docker commands

**Contains:**
- Image commands (build, tag, push, inspect)
- Container commands (run, exec, logs, stop)
- Network and volume commands
- Docker Compose commands
- Common workflows

**Read when:**
- Need a command quickly
- Can't remember syntax
- Want quick examples

**Time:** 2 minutes per lookup

---

### **ubi9-minimal-coder/README.md** - Case Study
**Purpose:** Deep dive into UBI9-minimal Coder template optimization

**Contains:**
- Business problem and requirements
- Three Dockerfile variants explained
- Size comparison and optimization strategies
- DevSecOps compliance checklist
- Coder platform deployment guide
- Customization examples

**Read when:**
- Working on the Coder template project
- Need to understand the business case
- Preparing DevSecOps review
- Deploying to Barclays platform

**Time:** 30-45 minutes

---

## 🎓 Use Case: UBI9-Minimal Coder Template

### Business Context

**Problem:**
- Current UBI8 images are bloated (~380MB+)
- General-purpose containers with unnecessary tools
- Slow cold starts in Coder platform
- Higher resource consumption and costs

**Solution:**
- UBI9-minimal optimized images (<200MB)
- Purpose-built for Claude Code skill hosting
- Coder console access only (no build tools)
- DevSecOps compliant (RHEL-based, non-root)

**Impact:**
- **60%+ size reduction** (380MB → 150MB)
- **Faster provisioning** (30%+ improvement)
- **Better security** (minimal attack surface)
- **Cost savings** (less storage, bandwidth, compute)

---

### Three Dockerfile Variants

#### 1. **Dockerfile** - Basic (Recommended for Starting)
```
Base: UBI9-minimal
Additions: Python 3.11 + pip
Size: ~150MB
Use case: Development, easy customization
```

**Pros:** Simple, includes pip, easy to extend  
**Cons:** Slightly larger than optimized

---

#### 2. **Dockerfile.optimized** - Ultra-Minimal
```
Stage 1: Full UBI9 (builder)
Stage 2: UBI9-minimal (runtime)
Size: ~130MB
Use case: Production deployment
```

**Pros:** Smallest size, best security  
**Cons:** Cannot install packages at runtime

---

#### 3. **Dockerfile.with-claude-code** - Ready-to-Use
```
Base: UBI9-minimal
Additions: Python + Claude Code + MCP packages
Size: ~180MB
Use case: Immediate Claude skill hosting
```

**Pros:** Ready for use, no setup  
**Cons:** Larger, locked package versions

---

## 🛠️ Helper Scripts

### **build-all.ps1**
Builds all three Dockerfile variants automatically.

```powershell
.\build-all.ps1
```

**Output:**
- coder-template:ubi9-basic
- coder-template:ubi9-optimized
- coder-template:ubi9-claude

---

### **compare-images.ps1**
Compares image sizes and shows reduction vs UBI8 baseline.

```powershell
.\compare-images.ps1
```

**Output:**
- Size of each variant
- Percentage reduction vs UBI8
- Recommendations for each use case

---

### **test-container.ps1**
Automated testing of container functionality.

```powershell
.\test-container.ps1 -Version basic
```

**Tests:**
- Python version verification
- Non-root user check
- Working directory correctness
- pip availability
- Claude Code installation (claude version)
- Shell access
- Environment variables

---

### **test-setup.ps1**
Verifies Docker installation and readiness.

```powershell
.\test-setup.ps1
```

**Checks:**
- Docker installed and running
- UBI9 registry access
- VSCode installation (optional)
- Disk space availability

---

## 🎯 Success Metrics

After completing this lab, you should achieve:

### Knowledge
- [ ] Explain Docker images vs containers
- [ ] Write a Dockerfile from scratch
- [ ] Understand multi-stage builds
- [ ] Apply security best practices

### Skills
- [ ] Build optimized UBI9-minimal images
- [ ] Reduce image size by 60%+
- [ ] Create non-root secure containers
- [ ] Test containers systematically

### Deliverables
- [ ] Three UBI9-minimal variants (<200MB each)
- [ ] Automated build and test scripts
- [ ] DevSecOps-compliant Dockerfile
- [ ] Documentation for team handoff

---

## 🚀 Deployment Workflow

### 1. Development
```powershell
# Build and test locally
cd ubi9-minimal-coder
docker build -t coder-template:dev -f Dockerfile .
docker run -it --rm coder-template:dev
```

### 2. Optimization
```powershell
# Build optimized version
docker build -t coder-template:optimized -f Dockerfile.optimized .

# Compare sizes
.\compare-images.ps1
```

### 3. Testing
```powershell
# Automated tests
.\test-container.ps1 -Version optimized

# Manual testing
docker run -it --rm coder-template:optimized /bin/bash
```

### 4. Security Review
- Run image scanning: `docker scan coder-template:optimized`
- Check DevSecOps compliance checklist
- Share with William Burton for approval

### 5. Registry Push
```powershell
# Tag for internal registry
docker tag coder-template:optimized barclays-registry.io/coder-templates/ubi9-python:1.0

# Push
docker push barclays-registry.io/coder-templates/ubi9-python:1.0
```

### 6. Coder Deployment
```bash
# Update Coder template (see coder-template.yaml)
coder template push ubi9-python-minimal

# Test workspace creation
coder create test-workspace --template ubi9-python-minimal
```

---

## 📊 Comparison: Before vs After

### Before (UBI8 General-Purpose)
```
Base image: UBI8 full                    ~230MB
Python 3.9 + dev tools                   +100MB
Miscellaneous packages                   +50MB
────────────────────────────────────────────────
Total:                                   ~380MB
Cold start time:                         ~45 seconds
Security: High attack surface (many packages)
```

### After (UBI9-Minimal Optimized)
```
Base image: UBI9-minimal                 ~100MB
Python 3.11 (runtime only)               +30MB
────────────────────────────────────────────────
Total:                                   ~130MB
Cold start time:                         ~15 seconds
Security: Minimal attack surface
```

### Results
- **Size reduction:** 66% smaller (250MB saved)
- **Speed improvement:** 67% faster cold start
- **Security:** Fewer packages = fewer vulnerabilities
- **Cost savings:** Less storage, bandwidth, compute

---

## 🆘 Troubleshooting

### Common Issues

**"Cannot pull UBI9 images"**
- Check VPN connection (Barclays network required)
- Verify registry access: `docker pull registry.access.redhat.com/ubi9/ubi-minimal`

**"Build fails at microdnf install"**
- Base image may not have microdnf (use `ubi9-minimal`, not `ubi9-micro`)
- Check package name spelling

**"Image size too large"**
- Ensure `microdnf clean all` is included
- Use multi-stage build (Dockerfile.optimized)
- Check: `docker history <image>` for large layers

**"Permission denied in container"**
- You're running as 'coder' user (non-root) - this is correct!
- For root access: `docker run --user root -it <image>`

---

## 📚 External Resources

- [Docker Documentation](https://docs.docker.com/)
- [UBI9 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9)
- [Red Hat UBI Container Images](https://catalog.redhat.com/software/containers/ubi9/ubi-minimal/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## ✅ Next Steps

1. **Complete QUICKSTART.md** (15 mins)
2. **Build all three variants** with `build-all.ps1`
3. **Study the Dockerfiles** - understand each instruction
4. **Customize for your needs** - add/remove packages
5. **Share with William Burton** - get DevSecOps approval
6. **Deploy to Coder platform** - test in production
7. **Document lessons learned** - help the team

---

**Questions? Check README.md or ask William Burton (DevSecOps Team Lead)!** 🚀
