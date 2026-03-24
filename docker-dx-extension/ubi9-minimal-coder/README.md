# UBI9-Minimal Coder Template

**Production-ready minimal Docker image for Claude Code skill hosting in Barclays Coder platform.**

---

## ⚠️ IMPORTANT: Claude Code is Node.js, Not Python!

**Claude Code CLI:**
- **Package:** `@anthropic-ai/claude-code`
- **Install:** `npm install -g @anthropic-ai/claude-code`
- **Requires:** Node.js + npm
- **GitHub:** https://github.com/anthropics/claude-code

**Don't confuse with:**
- `anthropic` (Python SDK) - for custom apps using Claude API

---

## 🎯 Business Problem

**Current State:**
- Large customized UBI8 images (~380MB+)
- General-purpose containers with unnecessary tools
- Slow cold starts in Coder platform
- Higher resource consumption

**Target State:**
- UBI9-minimal optimized images (<280MB)
- Purpose-built for Claude Code CLI + MCP servers
- Faster provisioning and better efficiency
- DevSecOps compliant (RHEL-based, non-root user)

**Success Metrics:**
- Image size reduction: 26%+ (380MB → 280MB for complete setup)
- Cold start time: 30%+ faster
- Security: Minimal attack surface, approved by DevSecOps

---

## 📦 Four Dockerfile Options

### 1. **Dockerfile** - Python Only (~150MB)
```dockerfile
FROM ubi9-minimal + Python 3.11 + pip
Size: ~150MB
Use case: Python MCP development (no Claude Code CLI)
```

**Pros:**
- ✅ Smallest with Python
- ✅ Includes pip for packages
- ✅ Easy to extend

**Cons:**
- ❌ No Claude Code CLI (no Node.js)

**Use when:** Building Python MCP servers only

---

### 2. **Dockerfile.optimized** - Python Multi-Stage (~130MB)
```dockerfile
Stage 1: Build with full UBI9
Stage 2: Runtime with ubi9-minimal
Size: ~130MB
Use case: Production Python apps (no Claude Code)
```

**Pros:**
- ✅ Smallest possible with Python
- ✅ Best security (minimal dependencies)

**Cons:**
- ❌ Cannot install packages at runtime
- ❌ No Claude Code CLI

**Use when:** Production Python MCP servers, no Claude Code needed

---

### 3. **Dockerfile.with-claude-code** - Claude Code Only (~250MB)
```dockerfile
FROM ubi9-minimal + Node.js + npm + @anthropic-ai/claude-code
Size: ~250MB
Use case: Claude Code CLI only (no Python MCP servers)
```

**Pros:**
- ✅ Claude Code CLI ready to use
- ✅ Smaller than complete setup
- ✅ npm available for additional packages

**Cons:**
- ❌ No Python for MCP servers

**Use when:** Only need Claude Code CLI, no Python MCP development

---

### 4. **Dockerfile.with-both** - Complete Setup (~280MB) ⭐ RECOMMENDED
```dockerfile
FROM ubi9-minimal
+ Node.js + npm (for Claude Code CLI)
+ Python 3.11 (for MCP servers)
+ @anthropic-ai/claude-code
+ anthropic (Python SDK)
Size: ~280MB
```

**Pros:**
- ✅ Claude Code CLI + Python MCP servers
- ✅ Both npm and pip available
- ✅ Complete development environment
- ✅ Still 26% smaller than UBI8 (~380MB)

**Cons:**
- ❌ Larger than single-runtime versions

**Use when:** Coder platform with Claude Code + Python MCP servers (most common!)

---

## 🚀 Quick Start

### Build the Complete Version (Recommended)

```bash
cd C:\code\DevOps-labs\ubi9-minimal-coder

# Build complete setup (Claude Code + Python)
docker build -t coder-template:complete -f Dockerfile.with-both .

# Check size
docker images | findstr coder-template
```

**Expected:** ~280MB (still 26% smaller than UBI8!)

---

### Test Claude Code CLI

```bash
# Run interactively
docker run -it --rm coder-template:complete

# Inside container:
claude --version    # ✅ Claude Code CLI
node --version           # Node.js runtime
npm --version            # Package manager
python3 --version        # For MCP servers
pip3 --version            # Python packages

# Exit
exit
```

---

### Build All Variants

```bash
# Build all four versions
.\build-all.ps1

# Results:
# - coder-template:ubi9-basic      (~150MB) - Python only
# - coder-template:ubi9-optimized  (~130MB) - Python optimized
# - coder-template:ubi9-claude     (~250MB) - Claude Code CLI only
# - coder-template:ubi9-complete   (~280MB) - Complete setup ⭐

# Compare sizes
.\compare-images.ps1
```

---

### Test Containers

```bash
# Test complete version
.\test-container.ps1 -Version complete

# Test Claude Code only
.\test-container.ps1 -Version claude

# Test Python only
.\test-container.ps1 -Version basic
```

---

## 📊 Size Comparison

### Baseline (Current UBI8 Setup)

```
UBI8 base:                    ~230MB
+ Python 3.9:                 +50MB
+ Development tools:          +100MB
────────────────────────────────────
Total:                        ~380MB
```

### UBI9-Minimal Options

| Version | Size | Runtime | Claude Code CLI | Use Case |
|---------|------|---------|-----------------|----------|
| **Basic** | ~150MB | Python | ❌ | Python MCP dev |
| **Optimized** | ~130MB | Python | ❌ | Python production |
| **Claude Code** | ~250MB | Node.js | ✅ | Claude Code only |
| **Complete** ⭐ | ~280MB | Node + Python | ✅ | Full Coder setup |

### Why Node.js Adds Size

- **UBI9-minimal base:** ~100MB
- **+ Node.js runtime:** +80MB
- **+ npm + packages:** +20MB
- **+ Claude Code:** +50MB
- **+ Python (complete):** +30MB

**Result:** 280MB complete setup (still 26% smaller than UBI8!)

---

## 🔧 Customization Guide

### Add Claude Code + Additional npm Packages

```dockerfile
# In Dockerfile.with-claude-code or Dockerfile.with-both
USER coder

RUN npm install -g \
    @anthropic-ai/claude-code \
    your-additional-package
```

---

### Add Python Packages to Complete Version

```dockerfile
# In Dockerfile.with-both
RUN python3 -m pip install --user --no-cache-dir \
    anthropic \
    httpx \
    your-package-here
```

---

### Add System Packages

```dockerfile
# Before microdnf clean
RUN microdnf install -y \
    nodejs \
    npm \
    python3.11 \
    git \          # Add git
    && microdnf clean all
```

**⚠️ Warning:** Every package increases image size!

---

## 🔒 Security Features

### 1. Non-Root User
```dockerfile
RUN useradd -m -u 1000 coder
USER coder
```
- ✅ Runs as `coder` user (UID 1000)
- ✅ No root privileges

### 2. Minimal Attack Surface
- ✅ Only essential packages
- ✅ No compilers or dev tools in runtime
- ✅ Package cache removed

### 3. RHEL-Based (UBI9)
- ✅ Red Hat Enterprise Linux 9
- ✅ Approved for Barclays
- ✅ Regular security updates

---

## 🎯 DevSecOps Compliance Checklist

**For William Burton's Review:**

- [x] **Base Image:** UBI9-minimal (approved RHEL base)
- [x] **User:** Non-root (`coder` user, UID 1000)
- [x] **Size:** <300MB (optimized)
- [x] **Security:** Minimal packages, no dev tools in runtime
- [x] **Reproducibility:** Specific package versions
- [x] **Labels:** Metadata for tracking
- [x] **.dockerignore:** Excludes sensitive files
- [x] **Claude Code:** Installed via npm (official package)

---

## 🐛 Debugging

### Check Claude Code Installation

```bash
docker run --rm coder-template:complete claude-code --version
# Should show: @anthropic-ai/claude-code@X.X.X
```

### Test with API Key

```bash
docker run -it --rm \
  -e ANTHROPIC_API_KEY=your-key-here \
  coder-template:complete

# Inside container:
claude-code chat "Hello from UBI9!"
```

### Debug Build Issues

```bash
# Build with verbose output
docker build --progress=plain --no-cache \
  -t test -f Dockerfile.with-both .

# Check layer sizes
docker history coder-template:complete
```

---

## 🚀 Deployment to Coder

### 1. Tag for Registry

```bash
docker tag coder-template:complete \
  barclays-registry.io/coder-templates/ubi9-claude:1.0
```

### 2. Push to Registry

```bash
docker push barclays-registry.io/coder-templates/ubi9-claude:1.0
```

### 3. Update Coder Template

See `coder-template.yaml` for example configuration.

---

## 📝 Files in This Directory

```
ubi9-minimal-coder/
├── README.md                       # This file (corrected!)
├── Dockerfile                      # Python only (~150MB)
├── Dockerfile.optimized            # Python multi-stage (~130MB)
├── Dockerfile.with-claude-code     # Claude Code CLI only (~250MB)
├── Dockerfile.with-both            # Complete setup (~280MB) ⭐
├── .dockerignore                   # Build optimization
├── build-all.ps1                   # Build all versions
├── compare-images.ps1              # Size comparison
├── test-container.ps1              # Automated testing
├── coder-template.yaml             # Coder platform config
└── example-claude-skill.py         # Test script
```

---

## ❓ FAQ

### Q: Do I need Python or Node.js for Claude Code?
**A:** **Node.js!** Claude Code is `@anthropic-ai/claude-code` (npm package).

Python's `anthropic` package is only for building custom apps with Claude API, not the Claude Code CLI.

### Q: Which Dockerfile should I use?
**A:** For Coder platform with Claude Code:
- Use **`Dockerfile.with-both`** (complete setup)
- Includes Claude Code CLI + Python for MCP servers
- Size: ~280MB (still 26% smaller than UBI8)

### Q: Why is the complete version larger?
**A:** Node.js adds ~100MB to the base. But:
- Still 26% smaller than UBI8 bloated setup
- Includes both runtimes (Node + Python)
- Complete development environment

### Q: Can I make it smaller?
**A:** Yes, but trade-offs:
- **Python only:** ~150MB (no Claude Code CLI)
- **Claude Code only:** ~250MB (no Python MCP servers)
- **Complete:** ~280MB (everything you need) ⭐

---

## 📚 Resources

- [Claude Code GitHub](https://github.com/anthropics/claude-code)
- [UBI9 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## ✅ Next Steps

1. **Build the complete version:**
   ```bash
   docker build -t coder-template:complete -f Dockerfile.with-both .
   ```

2. **Test Claude Code CLI:**
   ```bash
   docker run -it --rm coder-template:complete
   claude --version
   ```

---

**Questions? Check the parent README.md or CHEATSHEET.md!** 🚀
https://www.docker.com/blog/docker-dx-extension-for-vs-code/
