# 🚀 Get Started with DevOps Labs

**Welcome to your Docker learning journey with UBI9-minimal optimization!**

---

## ⚡ Quick Start (5 minutes)

### 1. Verify Setup
```powershell
cd C:\code\DevOps-labs
.\test-setup.ps1
```
✅ Should show all green checkmarks

### 2. Follow 15-Minute Guide
```powershell
# Open the quick start guide
code QUICKSTART.md
```

### 3. Build Your First Image
```powershell
cd ubi9-minimal-coder
docker build -t coder-template:ubi9-basic -f Dockerfile .
```

### 4. Test It
```powershell
docker run -it --rm coder-template:ubi9-basic
```

**🎉 Done! You've built a production-grade minimal container!**

---

## 📚 What's In This Project?

### 📖 Core Documentation
- **[QUICKSTART.md](QUICKSTART.md)** - 15-minute hands-on guide (START HERE!)
- **[README.md](README.md)** - Comprehensive Docker tutorial
- **[CHEATSHEET.md](CHEATSHEET.md)** - Quick command reference
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Detailed project overview

### 🎯 UBI9-Minimal Case Study
- **[ubi9-minimal-coder/](ubi9-minimal-coder/)** - Real-world optimization project
  - Four Dockerfile variants (basic, optimized, claude-code, complete)
  - Automated build and test scripts
  - Complete documentation
  - Example Claude Code skill

### 🤖 Docker DX Extension Lab
- **[docker-dx-extension/](docker-dx-extension/)** - AI-powered Docker workflows
  - AI Dockerfile generation
  - Container insights and debugging
  - Optimization with AI suggestions
  - Hands-on demo app included

### 🛠️ Helper Scripts
- **test-setup.ps1** - Verify Docker installation
- **build-all.ps1** - Build all variants (in ubi9-minimal-coder/)
- **compare-images.ps1** - Compare image sizes
- **test-container.ps1** - Automated testing

---

## 🎓 Learning Paths

### 🟢 Beginner (1-2 hours)
New to Docker? Start here!

1. Run `test-setup.ps1`
2. Read **QUICKSTART.md** (hands-on practice)
3. Build basic UBI9-minimal image
4. Test interactively
5. Keep **CHEATSHEET.md** open for reference

**You'll learn:** Docker basics, image building, container management

---

### 🟡 Intermediate (2-4 hours)
Know the basics, want production skills?

1. Read full **README.md**
2. Study all three Dockerfiles
3. Build and compare all variants
4. Run automated tests
5. Customize a Dockerfile

**You'll learn:** Multi-stage builds, optimization, security, DevSecOps

---

### 🔴 Advanced (4+ hours)
Ready for Barclays deployment?

1. Optimize image to <120MB
2. Complete DevSecOps checklist
3. Test against security gates
4. Deploy to Coder platform
5. Document for team handoff

**You'll learn:** Advanced optimization, security hardening, production deployment

---

## 🎯 The Business Case

### Problem
- Current UBI8 images: **~380MB** (bloated!)
- General-purpose containers with unnecessary tools
- Slow cold starts in Coder platform
- Higher costs (storage, bandwidth, compute)

### Solution (Your Mission!)
- UBI9-minimal optimized images: **<200MB**
- Purpose-built for Claude Code skill hosting
- Coder console access only (no build tools)
- DevSecOps compliant (RHEL-based, non-root)

### Impact
- **📉 60%+ size reduction** (380MB → 150MB)
- **⚡ 30%+ faster** cold starts
- **🔒 Better security** (minimal attack surface)
- **💰 Cost savings** (less resources needed)

---

## 🔥 What Makes This Different?

### ✅ Production-Ready
- Real Barclays use case (Coder template optimization)
- DevSecOps compliant Dockerfiles
- Security best practices baked in

### ✅ Hands-On Learning
- Three working Dockerfile variants
- Automated build and test scripts
- Example Claude Code skill

### ✅ Complete Documentation
- Step-by-step guides
- Detailed explanations
- Quick reference materials

### ✅ Measurable Results
- Clear "before vs after" comparison
- Automated size comparison tool
- Test suite for validation

---

## 📊 Your Success Path

```
┌─────────────────────┐
│  test-setup.ps1     │ ← Verify Docker works
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  QUICKSTART.md      │ ← 15-minute hands-on
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Build UBI9-minimal │ ← docker build ...
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Test & Compare     │ ← ./test-container.ps1
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Optimize & Deploy  │ ← Multi-stage build
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Share with Will    │ ← DevSecOps review
└─────────────────────┘
```

---

## 💡 Pro Tips

### For Immediate Impact
```powershell
# Build all three variants at once
cd ubi9-minimal-coder
.\build-all.ps1

# Compare sizes automatically
.\compare-images.ps1
```

### For Learning
- Open Dockerfiles side-by-side in VSCode
- Compare basic vs optimized approaches
- Run `docker history <image>` to see layer sizes
- Experiment with adding/removing packages

### For Barclays Deployment
1. Follow DevSecOps checklist in ubi9-minimal-coder/README.md
2. Test against security gates
3. Share with William Burton for approval
4. Document your optimization results

---

## 🆘 Need Help?

### Quick Answers
- **Common commands:** Check CHEATSHEET.md
- **Step-by-step:** Follow QUICKSTART.md
- **Deep dive:** Read full README.md
- **Troubleshooting:** See PROJECT_STRUCTURE.md

### Stuck?
1. Run `test-setup.ps1` to verify environment
2. Check error message in QUICKSTART.md troubleshooting section
3. Review Dockerfile comments for explanations
4. Compare your output with expected results

---

## 🎯 Next Steps

### Right Now (5 minutes)
```powershell
.\test-setup.ps1
code QUICKSTART.md
```

### Today (1-2 hours)
- Complete QUICKSTART.md guide
- Build all three Dockerfile variants
- Test interactively

### This Week (4+ hours)
- Read full README.md
- Customize a Dockerfile for your needs
- Share results with William Burton

### This Month (Production!)
- Deploy to Coder platform
- Measure impact (size, speed, cost)
- Document lessons learned
- Train your team

---

## 📈 Success Metrics

By the end of this lab, you will:

- [x] **Understand** Docker images vs containers
- [x] **Build** production-grade UBI9-minimal images
- [x] **Achieve** 60%+ size reduction vs UBI8
- [x] **Apply** DevSecOps best practices
- [x] **Deploy** to Barclays Coder platform
- [x] **Demonstrate** measurable improvements

---

## 🎉 Ready to Start?

### The Fastest Path to Success
```powershell
# 1. Verify setup (2 mins)
.\test-setup.ps1

# 2. Quick start guide (15 mins)
code QUICKSTART.md

# 3. Build your first image (3 mins)
cd ubi9-minimal-coder
docker build -t coder-template:ubi9-basic -f Dockerfile .

# 4. Test it (2 mins)
docker run -it --rm coder-template:ubi9-basic
```

**Total time: 22 minutes to working knowledge! ⚡**

---

## 📞 Contact & Collaboration

**Share with:**
- **William Burton** (DevSecOps Team Lead) - For security approval
- **Your team** - For knowledge sharing
- **Platform team** - For Coder deployment

**Document:**
- Size reduction achieved
- Cold start time improvements
- Security compliance status
- Lessons learned

---

**Let's build minimal, secure, production-ready containers! 🐳**

**Questions? Start with QUICKSTART.md or check README.md!**
