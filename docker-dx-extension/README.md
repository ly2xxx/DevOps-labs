# Docker DX Extension for VS Code Lab

**Learn the new Docker Developer Experience (DX) extension for enhanced container workflows in VS Code.**

---

## 🎯 What is Docker DX Extension?

The **Docker DX extension** is Docker's next-generation VS Code extension that provides:

- 🤖 **AI-powered Dockerfile generation** (with Docker AI)
- 📊 **Enhanced container insights** and debugging
- 🚀 **Simplified workflows** for build, run, and deploy
- 🔍 **Better integration** with Docker Desktop
- 💡 **Intelligent suggestions** for optimization

**Official Blog:** https://www.docker.com/blog/docker-dx-extension-for-vs-code/

---

## 📦 Installation

### Prerequisites
- ✅ Docker Desktop installed and running
- ✅ VS Code installed
- ✅ OpenAI API key (for AI features - optional)

### Install the Extension

1. **Open VS Code**
2. **Go to Extensions** (Ctrl+Shift+X)
3. **Search for:** `Docker DX`
4. **Click Install** on "Docker DX" by Docker Inc.

**Alternative (Command Line):**
```bash
code --install-extension docker.docker-dx
```

---

## 🚀 Quick Start Lab

### Lab 1: AI-Powered Dockerfile Generation

**Goal:** Generate a Dockerfile using AI

1. **Create a new project folder:**
   ```powershell
   New-Item -ItemType Directory -Path "C:\code\DevOps-labs\docker-dx-extension\ai-dockerfile-demo"
   cd C:\code\DevOps-labs\docker-dx-extension\ai-dockerfile-demo
   ```

2. **Create a simple Node.js app:**
   ```powershell
   # Create package.json
   @"
   {
     "name": "hello-docker-dx",
     "version": "1.0.0",
     "main": "index.js",
     "scripts": {
       "start": "node index.js"
     },
     "dependencies": {
       "express": "^4.18.0"
     }
   }
   "@ | Out-File -FilePath "package.json" -Encoding UTF8
   
   # Create index.js
   @"
   const express = require('express');
   const app = express();
   const port = 3000;
   
   app.get('/', (req, res) => {
     res.send('Hello from Docker DX!');
   });
   
   app.listen(port, () => {
     console.log(`App listening at http://localhost:${port}`);
   });
   "@ | Out-File -FilePath "index.js" -Encoding UTF8
   ```

3. **Open in VS Code:**
   ```powershell
   code .
   ```

4. **Generate Dockerfile with AI:**
   - Press **Ctrl+Shift+P** (Command Palette)
   - Type: `Docker DX: Generate Dockerfile`
   - Follow prompts:
     - Platform: **Node.js**
     - Node version: **18** (or latest)
     - Package manager: **npm**
   
   **Or use AI assistant:**
   - Open Docker DX panel (Docker icon in sidebar)
   - Click "Ask AI" or "Generate Dockerfile"
   - Describe your app: "Express.js app on port 3000"

5. **Review Generated Dockerfile:**
   - Docker DX will create an optimized Dockerfile
   - Notice: Multi-stage build, security best practices
   - May include .dockerignore automatically

---

### Lab 2: Build and Run with Docker DX

1. **Build the image:**
   - Right-click `Dockerfile` → **Docker DX: Build Image**
   - Or use Docker DX panel: Click "Build"
   - Tag: `hello-docker-dx:latest`

2. **Run the container:**
   - In Docker DX panel, find your image
   - Click "Run" icon
   - Configure:
     - Port mapping: `3000:3000`
     - Name: `hello-app`
   
3. **Test it:**
   ```powershell
   curl http://localhost:3000
   # Should see: "Hello from Docker DX!"
   ```

4. **View container logs:**
   - Docker DX panel → Containers → `hello-app`
   - Click "Logs" to see real-time output

---

### Lab 3: Container Insights & Debugging

1. **Open Container Insights:**
   - Docker DX panel → Right-click container → **Insights**
   
   **You'll see:**
   - Resource usage (CPU, memory)
   - Port mappings
   - Environment variables
   - Volume mounts
   - Health status

2. **Debug running container:**
   - Right-click container → **Attach Shell**
   - Or click "Terminal" icon in Insights panel
   
   ```bash
   # Inside container:
   ls /app
   node --version
   npm list
   ```

3. **Inspect image layers:**
   - Docker DX panel → Images → Right-click → **Inspect Layers**
   - See size breakdown
   - Identify optimization opportunities

---

### Lab 4: AI-Powered Optimization

1. **Ask AI to optimize your Dockerfile:**
   - Open Dockerfile
   - Docker DX panel → "Ask AI"
   - Prompt: "Optimize this Dockerfile for production"
   
   **AI may suggest:**
   - Multi-stage builds
   - Alpine base images
   - Layer caching improvements
   - Security enhancements

2. **Apply suggestions:**
   - Review AI recommendations
   - Click "Apply" or manually edit
   - Rebuild and compare sizes:
     ```powershell
     docker images hello-docker-dx
     ```

---

### Lab 5: Compose Integration

1. **Generate docker-compose.yml:**
   - Ctrl+Shift+P → `Docker DX: Generate Compose File`
   - Or: Ask AI "Create docker-compose.yml for my app"

2. **AI-generated compose file example:**
   ```yaml
   version: '3.8'
   services:
     app:
       build: .
       ports:
         - "3000:3000"
       environment:
         - NODE_ENV=production
       restart: unless-stopped
   ```

3. **Start with Docker DX:**
   - Right-click `docker-compose.yml` → **Docker DX: Compose Up**
   - View all services in Docker DX panel

---

## 🎓 Advanced Features

### AI Dockerfile Assistant

**Use cases:**
```
"Create a Dockerfile for a Python Flask app with PostgreSQL"
"Optimize this Dockerfile for minimal size"
"Add multi-stage build for Node.js TypeScript app"
"Secure this Dockerfile (non-root user, minimal base)"
```

**How it works:**
1. Docker DX panel → "Ask AI"
2. Describe what you need
3. Review generated code
4. Click "Apply" or edit manually

---

### Smart Dockerfile Suggestions

As you type in a Dockerfile, Docker DX provides:
- **Auto-completion** for instructions
- **Inline suggestions** for optimization
- **Security warnings** (e.g., running as root)
- **Best practice tips**

---

### Container Performance Insights

**View detailed metrics:**
- CPU usage over time
- Memory consumption
- Network I/O
- Disk usage

**Access:**
- Docker DX panel → Container → "Performance"

---

### Image Layer Visualization

**Understand your image:**
- See size of each layer
- Identify large files
- Find optimization opportunities

**Access:**
- Docker DX panel → Image → "Layers"

---

## 🔧 Docker DX vs Classic Docker Extension

| Feature | Classic Docker Extension | Docker DX Extension |
|---------|-------------------------|---------------------|
| Basic build/run | ✅ | ✅ |
| Compose support | ✅ | ✅ Enhanced |
| AI Dockerfile generation | ❌ | ✅ |
| Container insights | Basic | ✅ Detailed |
| Performance metrics | ❌ | ✅ |
| Layer visualization | Basic | ✅ Enhanced |
| AI optimization tips | ❌ | ✅ |
| Interactive debugging | Manual | ✅ Streamlined |

**Recommendation:** Use Docker DX for enhanced AI-powered workflows!

---

## 🎯 Practical Exercise: UBI9-Minimal with Docker DX

**Goal:** Use Docker DX to optimize our UBI9-minimal Coder template

### Step 1: Open Project

```powershell
cd C:\code\DevOps-labs\ubi9-minimal-coder
code .
```

### Step 2: Ask AI for Optimization

1. Open `Dockerfile.with-both`
2. Docker DX panel → "Ask AI"
3. Prompt: "Optimize this UBI9-minimal Dockerfile for production. Keep Node.js + Python. Target size <250MB."

### Step 3: Review AI Suggestions

AI might suggest:
- Multi-stage build improvements
- Package cleanup optimizations
- Layer ordering changes
- Alternative base images

### Step 4: Apply & Compare

```powershell
# Build original
docker build -t original:v1 -f Dockerfile.with-both .

# Apply AI suggestions → save as Dockerfile.dx-optimized
docker build -t optimized:v1 -f Dockerfile.dx-optimized .

# Compare
docker images | findstr -E "original|optimized"
```

---

## 💡 Pro Tips

### 1. AI Context Awareness

Docker DX AI understands:
- Your project structure
- Existing dependencies (package.json, requirements.txt)
- Security requirements
- Target platform

**Tip:** Be specific in prompts:
```
"Create Dockerfile for Express.js app with:
- Node 18 Alpine
- Non-root user
- Multi-stage build
- Health check"
```

### 2. Iterative Refinement

```
1. "Generate Dockerfile for my app"
2. Review → "Make it smaller using Alpine"
3. Review → "Add security best practices"
4. Review → "Add health check"
```

### 3. Learn from AI

- Review AI-generated code carefully
- Read inline comments Docker DX adds
- Understand WHY certain patterns are used

### 4. Container Debugging

Use Docker DX's integrated terminal:
- Faster than `docker exec`
- Context-aware (sees your project)
- Can edit files and rebuild instantly

---

## 🧪 Hands-On Challenges

### Challenge 1: AI Dockerfile from Scratch

**Goal:** Generate optimal Dockerfile for a Python Flask API

1. Create minimal Flask app
2. Use Docker DX AI to generate Dockerfile
3. Target: <100MB image
4. Requirements: Non-root user, health check

### Challenge 2: Optimize Existing Dockerfile

**Goal:** Reduce UBI9-minimal complete version from 280MB to <250MB

1. Open `Dockerfile.with-both`
2. Ask Docker DX AI for optimization
3. Apply suggestions
4. Measure improvement

### Challenge 3: Multi-Container Setup

**Goal:** AI-generated docker-compose.yml for full stack

1. Node.js API + PostgreSQL + Redis
2. Use Docker DX AI to generate compose file
3. Add health checks and volumes
4. Deploy and test

---

## 🐛 Troubleshooting

### "AI features not working"

**Solution:** Configure OpenAI API key
1. Docker DX settings
2. Add API key
3. Restart VS Code

### "Docker DX panel not showing"

**Solution:**
1. Check Docker Desktop is running
2. Reload VS Code window (Ctrl+Shift+P → "Reload Window")
3. Check extension is enabled

### "Build fails with Docker DX"

**Solution:**
1. Check Dockerfile syntax
2. View build logs in Output panel
3. Try building manually: `docker build -t test .`
4. Compare with classic Docker extension behavior

---

## 📚 Resources

- [Docker DX Extension](https://marketplace.visualstudio.com/items?itemName=docker.docker-dx)
- [Official Blog Post](https://www.docker.com/blog/docker-dx-extension-for-vs-code/)
- [Docker AI Documentation](https://docs.docker.com/ai/)
- [VS Code Docker Docs](https://code.visualstudio.com/docs/containers/overview)

---

## ✅ Lab Completion Checklist

After completing this lab, you should be able to:

- [ ] Install and configure Docker DX extension
- [ ] Generate Dockerfiles using AI
- [ ] Build and run containers with enhanced UI
- [ ] View container insights and performance metrics
- [ ] Debug containers interactively
- [ ] Optimize Dockerfiles with AI suggestions
- [ ] Use AI for docker-compose generation
- [ ] Visualize image layers

---

## 🎯 Next Steps

1. **Try Docker DX with your own projects**
2. **Compare AI suggestions vs manual optimization**
3. **Use insights panel for production monitoring**
4. **Share AI-generated Dockerfiles with team**
5. **Experiment with different AI prompts**

---

**Docker DX makes containerization more accessible and AI-powered! 🚀**
