# Docker DX Extension - Quick Start (10 Minutes)

**Get started with AI-powered Docker development in VS Code!**

---

## ⚡ Setup (2 minutes)

### 1. Install Docker DX Extension

```bash
# From command line
code --install-extension docker.docker-dx
```

**Or manually:**
1. Open VS Code
2. Extensions (Ctrl+Shift+X)
3. Search "Docker DX"
4. Install "Docker DX" by Docker Inc.

### 2. Verify Docker Desktop Running

```powershell
docker --version
docker info
```

---

## 🚀 Try It Now (8 minutes)

### Lab 1: AI Dockerfile Generation (3 mins)

```powershell
# 1. Open demo app
cd C:\code\DevOps-labs\docker-dx-extension\ai-dockerfile-demo
code .

# 2. In VS Code: Generate Dockerfile with AI
# Press Ctrl+Shift+P → "Docker DX: Generate Dockerfile"
# Select: Node.js → version 18 → npm

# 3. Review the AI-generated Dockerfile
# Docker DX creates an optimized, multi-stage build!
```

### Lab 2: Build & Run (2 mins)

```powershell
# In VS Code:
# 1. Right-click Dockerfile → "Docker DX: Build Image"
#    Tag: hello-docker-dx:latest

# 2. Docker DX panel → Images → hello-docker-dx
#    Click "Run" → Map port 3000:3000

# 3. Test it
curl http://localhost:3000
```

**Expected response:**
```json
{
  "message": "Hello from Docker DX!",
  "timestamp": "2026-03-24T20:00:00.000Z",
  "environment": "development"
}
```

### Lab 3: Container Insights (2 mins)

```
1. Docker DX panel → Containers → hello-docker-dx
2. Click "Insights" icon
3. See real-time:
   - CPU usage
   - Memory consumption
   - Port mappings
   - Logs
```

### Lab 4: AI Optimization (1 min)

```
1. Open the generated Dockerfile
2. Docker DX panel → "Ask AI"
3. Prompt: "Make this Dockerfile smaller using Alpine base"
4. Review suggestions
5. Apply and rebuild
```

---

## 📊 Compare Sizes

```powershell
# Original (AI-generated)
docker images hello-docker-dx:latest

# Optimized (after AI suggestions)
docker images hello-docker-dx:optimized

# You should see 30-50% size reduction!
```

---

## 🎯 What You Just Learned

In 10 minutes, you:
- ✅ Installed Docker DX extension
- ✅ Generated Dockerfile with AI
- ✅ Built and ran container with enhanced UI
- ✅ Viewed container insights
- ✅ Optimized with AI suggestions

---

## 💡 Pro Tips

### AI Prompts That Work Well

```
"Create Dockerfile for Express app with Alpine base"
"Optimize for production with multi-stage build"
"Add non-root user and health check"
"Reduce image size below 100MB"
```

### Keyboard Shortcuts

- **Ctrl+Shift+P** → Docker DX commands
- **Right-click Dockerfile** → Quick actions
- **Docker DX panel** → Visual container management

---

## 🔥 Try Next

1. **Optimize UBI9-minimal Dockerfile:**
   ```powershell
   cd C:\code\DevOps-labs\ubi9-minimal-coder
   code Dockerfile.with-both
   # Ask AI: "Optimize this for production, keep Node.js + Python"
   ```

2. **Generate docker-compose.yml:**
   ```
   Docker DX → "Ask AI"
   Prompt: "Create docker-compose.yml with app + PostgreSQL"
   ```

3. **Debug running container:**
   ```
   Docker DX panel → Container → Right-click → "Attach Shell"
   ```

---

## ❓ Troubleshooting

**Docker DX panel not showing?**
- Ensure Docker Desktop is running
- Reload VS Code: Ctrl+Shift+P → "Reload Window"

**AI features not working?**
- May need OpenAI API key (check Docker DX settings)
- Or use non-AI features (still very useful!)

**Build fails?**
- Check Dockerfile syntax
- View Output panel (Ctrl+Shift+U) → "Docker DX"

---

## 📚 Next Steps

**Full lab:** [README.md](README.md) - Comprehensive Docker DX guide  
**Main labs:** [../README.md](../README.md) - All Docker labs  
**UBI9 case study:** [../ubi9-minimal-coder/](../ubi9-minimal-coder/)

---

**You're now ready to use AI-powered Docker workflows! 🚀**

**Questions? Check the full README.md or Docker DX documentation.**
