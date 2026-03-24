# Docker Labs - DevOps Learning

Practical Docker tutorials with real-world use cases for Barclays platform engineering.

## 📚 Contents

1. **Docker Fundamentals** - Core concepts and commands
2. **UBI9-Minimal Coder Template** - Production-ready minimal image case study
3. **VSCode Debugging** - Debug containerized applications
4. **Best Practices** - Security, optimization, production patterns

---

## 🎯 Use Case: UBI9-Minimal Coder Template

**Business Context:**  
Replace bloated general-purpose UBI8 images with optimized UBI9-minimal templates for internal Claude skill hosting. Goal: Faster cold starts, better resource efficiency, DevSecOps compliance.

**Requirements:**
- ✅ UBI9-minimal base (RHEL compliance for Barclays)
- ✅ Python 3.11+ (for Claude Code + MCP servers)
- ✅ Coder console access only (no build tools)
- ✅ Minimal size (<200MB target)
- ✅ Security: non-root user, minimal attack surface

**See:** `ubi9-minimal-coder/` for complete implementation

---

## 🚀 Quick Start

```bash
# Navigate to project
cd C:\code\DevOps-labs

# Test your Docker setup
.\test-setup.ps1

# Try the UBI9-minimal example
cd ubi9-minimal-coder
docker build -t coder-template:ubi9 .
docker images | findstr coder-template  # Check size

# Run it
docker run -p 8080:8080 coder-template:ubi9
```

---

## 📖 Learning Path

### 1️⃣ Docker Basics (Start Here)
- [QUICKSTART.md](QUICKSTART.md) - 15-minute hands-on guide
- [DOCKER_BASICS.md](DOCKER_BASICS.md) - Core concepts explained
- [CHEATSHEET.md](CHEATSHEET.md) - Command reference

### 2️⃣ UBI9-Minimal Case Study
- [ubi9-minimal-coder/README.md](ubi9-minimal-coder/README.md) - Implementation guide
- Learn image size optimization
- Apply DevSecOps best practices
- Understand Coder workspace requirements

### 3️⃣ Advanced Topics
- Multi-stage builds for minimal images
- Security hardening (non-root, minimal packages)
- VSCode debugging setup
- Production deployment patterns

---

## 🔧 Docker Fundamentals

### What is Docker?

**Docker** packages applications into **containers** - lightweight, portable units that run consistently everywhere.

**Key Benefits:**
- ✅ Consistent environments (dev = staging = prod)
- ✅ Fast startup (seconds vs minutes for VMs)
- ✅ Efficient resource usage (shared kernel)
- ✅ Easy scaling and deployment

### Core Concepts

```
┌─────────────────────────────────────┐
│         Dockerfile                  │  ← Recipe (text file)
│  Instructions to build image        │
└──────────────┬──────────────────────┘
               │ docker build
               ▼
┌─────────────────────────────────────┐
│         Image                       │  ← Template (read-only)
│  Snapshot with app + dependencies   │
└──────────────┬──────────────────────┘
               │ docker run
               ▼
┌─────────────────────────────────────┐
│         Container                   │  ← Running instance
│  Isolated process with its own FS   │
└─────────────────────────────────────┘
```

**Analogy:**
- **Dockerfile** = Recipe for a cake
- **Image** = Cake template/mold
- **Container** = Actual cake you eat

---

## 📦 Essential Commands

### Build & Run
```bash
# Build image from Dockerfile
docker build -t myapp:latest .

# Run container
docker run -p 8080:5000 myapp:latest

# Run in background with name
docker run -d --name myapp-prod -p 8080:5000 myapp:latest

# Run interactively (shell access)
docker run -it myapp:latest /bin/bash
```

### Manage Containers
```bash
# List running containers
docker ps

# List all containers
docker ps -a

# View logs
docker logs -f <container-id>

# Shell into running container
docker exec -it <container-id> /bin/bash

# Stop/Start/Restart
docker stop <container-id>
docker start <container-id>
docker restart <container-id>

# Remove container
docker rm <container-id>
```

### Manage Images
```bash
# List images
docker images

# Remove image
docker rmi <image-name>

# Tag image
docker tag myapp:latest myapp:v1.0

# Inspect image
docker inspect myapp:latest
docker history myapp:latest  # Show layers
```

### Cleanup
```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove everything unused
docker system prune -a
```

---

## 🏗️ Dockerfile Basics

### Structure

```dockerfile
# 1. Base image (starting point)
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# 2. Set working directory
WORKDIR /app

# 3. Copy files
COPY requirements.txt .

# 4. Run commands (install dependencies)
RUN microdnf install -y python3.11 && \
    microdnf clean all

# 5. Copy application code
COPY . .

# 6. Set environment variables
ENV PATH="/app/.local/bin:$PATH"

# 7. Create non-root user
RUN useradd -m -u 1000 coder
USER coder

# 8. Expose port (documentation)
EXPOSE 8080

# 9. Default command
CMD ["python3", "app.py"]
```

### Layer Optimization

**❌ BAD (creates many layers, slow builds):**
```dockerfile
RUN microdnf install python3
RUN microdnf install git
RUN microdnf clean all
```

**✅ GOOD (single layer, faster builds):**
```dockerfile
RUN microdnf install -y python3 git && \
    microdnf clean all
```

### Caching Strategy

**Order matters!** Docker caches each layer. Put rarely-changed files first:

```dockerfile
# 1. Install dependencies (changes rarely) ← Cached most
COPY requirements.txt .
RUN pip install -r requirements.txt

# 2. Copy app code (changes frequently) ← Cache breaks here
COPY . .
```

If you change `app.py`, only the last layer rebuilds. Dependencies stay cached!

---

## 🔒 Security Best Practices

### 1. Use Minimal Base Images
```dockerfile
# ✅ Minimal (~100MB)
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# ❌ Full OS (~200MB+)
FROM registry.access.redhat.com/ubi9/ubi:latest
```

### 2. Run as Non-Root User
```dockerfile
# Create user and switch
RUN useradd -m -u 1000 appuser
USER appuser

# All subsequent commands run as appuser (safer)
```

### 3. Use Specific Versions
```dockerfile
# ✅ Reproducible builds
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.3

# ❌ Unpredictable (latest changes)
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
```

### 4. Minimize Attack Surface
```dockerfile
# Only install what you need
RUN microdnf install -y python3.11 && \
    microdnf clean all  # ← Remove package cache

# Don't include dev tools in production
```

### 5. Use .dockerignore
```
# Exclude from image
.git
.venv
__pycache__
*.pyc
.env
secrets/
```

---

## 📊 Image Size Optimization

### Comparison

| Base Image | Size | Use Case |
|------------|------|----------|
| **ubi9-minimal** | ~100MB | Production (minimal, secure) |
| **ubi9** | ~200MB | Development (more tools) |
| **ubi8** | ~200MB+ | Legacy compatibility |
| **ubi9-micro** | ~30MB | Ultra-minimal (like distroless) |

### Multi-Stage Builds

**Problem:** Build tools inflate image size  
**Solution:** Build in one stage, copy only runtime artifacts

```dockerfile
# Stage 1: Build environment
FROM registry.access.redhat.com/ubi9/ubi:latest AS builder
RUN microdnf install -y python3.11 gcc
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Stage 2: Runtime (minimal)
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
RUN microdnf install -y python3.11
COPY --from=builder /root/.local /root/.local
COPY app.py .
CMD ["python3", "app.py"]
```

**Result:** Final image only has Python runtime + app (no gcc, no build cache).

---

## 🧪 UBI9-Minimal vs UBI8 Comparison

### Why UBI9-Minimal?

**UBI9 Improvements:**
- ✅ Smaller base image (~100MB vs ~200MB)
- ✅ Better security updates (RHEL 9 base)
- ✅ Python 3.11+ support (UBI8 has 3.8/3.9)
- ✅ Modern package versions
- ✅ Better container optimization

**UBI8 (Current bloated image):**
- ❌ Larger base (~200MB+)
- ❌ Includes unnecessary tools
- ❌ Older Python versions
- ❌ More attack surface

**Size Comparison:**
```bash
# UBI8 general-purpose
FROM ubi8:latest        # ~230MB
+ python3.9             # +50MB
+ dev tools             # +100MB
= 380MB+ final

# UBI9-minimal optimized
FROM ubi9-minimal       # ~100MB
+ python3.11            # +30MB
+ minimal deps          # +20MB
= 150MB final
```

**Savings: ~230MB (~60% reduction!)**

---

## 🎯 Coder Template Requirements

### What Coder Needs

**Coder** is an IDE platform that provisions cloud workspaces. For Claude skill hosting:

**Required:**
- Python runtime (for Claude Code + MCP servers)
- Basic shell access (for Coder console)
- Network access (for AI API calls)
- User with home directory

**NOT Required:**
- Git (no source control in skill hosting)
- Compilers (no building, just running)
- Text editors (Coder provides web IDE)
- SSH server (Coder handles access)

**Optimized Dockerfile:**
```dockerfile
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Install only Python
RUN microdnf install -y python3.11 && \
    microdnf clean all

# Create Coder user
RUN useradd -m -u 1000 coder
USER coder
WORKDIR /home/coder

# Install Claude Code (if needed)
RUN pip install --user claude-code

CMD ["/bin/bash"]
```

**Result: ~150MB image with everything needed, nothing extra.**

---

## 🐛 VSCode Debugging

### Setup

1. **Install VSCode Docker Extension**
   ```bash
   code --install-extension ms-azuretools.vscode-docker
   ```

2. **Add Debug Configuration** (`.vscode/launch.json`):
   ```json
   {
     "type": "docker",
     "request": "launch",
     "preLaunchTask": "docker-run: debug",
     "python": {
       "pathMappings": [
         {
           "localRoot": "${workspaceFolder}",
           "remoteRoot": "/app"
         }
       ]
     }
   }
   ```

3. **Press F5** - VSCode builds, runs, and attaches debugger!

**See:** `ubi9-minimal-coder/.vscode/` for complete config

---

## 📚 Resources

### Official Documentation
- [Docker Docs](https://docs.docker.com/)
- [UBI9 Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)

### Barclays Internal
- DevSecOps security gates
- Approved base images registry
- Coder platform documentation

### This Project
- [QUICKSTART.md](QUICKSTART.md) - Get started in 15 mins
- [CHEATSHEET.md](CHEATSHEET.md) - Quick command reference
- [ubi9-minimal-coder/](ubi9-minimal-coder/) - Real-world case study

---

## ✅ Success Checklist

After this tutorial, you should be able to:

- [ ] Explain Docker images vs containers
- [ ] Write a Dockerfile from scratch
- [ ] Build and run containers
- [ ] Optimize images for size (<200MB)
- [ ] Apply security best practices (non-root, minimal base)
- [ ] Debug containerized apps in VSCode
- [ ] Create production-ready Coder templates
- [ ] Pass Barclays DevSecOps security gates

---

## 🚀 Next Steps

1. **Complete the UBI9-minimal example** in `ubi9-minimal-coder/`
2. **Test against Barclays security gates**
3. **Deploy to Coder platform**
4. **Share results with William Burton** (DevSecOps validation)
5. **Create more optimized templates** for other use cases

---

**Let's build minimal, secure, production-ready containers! 🐳**
