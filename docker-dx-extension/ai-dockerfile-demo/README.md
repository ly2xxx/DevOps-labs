# Docker DX Demo App

Simple Express.js app for testing Docker DX extension features.

## 🚀 Quick Start (Local)

```bash
# Install dependencies
npm install

# Run locally
npm start

# Test
curl http://localhost:3000
```

## 🐳 Docker DX Lab Steps

### 1. Generate Dockerfile with AI

1. Open this folder in VS Code: `code .`
2. Press **Ctrl+Shift+P** → `Docker DX: Generate Dockerfile`
3. Select **Node.js** → version **18** → **npm**

**Or ask AI:**
- Docker DX panel → "Ask AI"
- Prompt: "Create an optimized Dockerfile for this Express.js app"

### 2. Build with Docker DX

- Right-click `Dockerfile` → **Docker DX: Build Image**
- Tag: `hello-docker-dx:latest`

### 3. Run with Docker DX

- Docker DX panel → Images → `hello-docker-dx`
- Click "Run" → Map port `3000:3000`

### 4. Test

```bash
curl http://localhost:3000
curl http://localhost:3000/health
curl http://localhost:3000/api/info
```

## 📊 Endpoints

- `GET /` - Hello message with timestamp
- `GET /health` - Health check (for Docker health checks)
- `GET /api/info` - App and system information

## 🎯 Optimization Challenge

**Goal:** Reduce Dockerfile size to <150MB

**Ask Docker DX AI:**
```
"Optimize this Dockerfile for production:
- Use Alpine base image
- Multi-stage build
- Non-root user
- Target size <150MB"
```

**Compare results:**
```bash
docker images hello-docker-dx
```

## 🔧 Docker DX Features to Try

1. **AI Dockerfile Generation** - Let AI create optimal Dockerfile
2. **Container Insights** - View resource usage in real-time
3. **Layer Visualization** - See what's making your image large
4. **Interactive Debugging** - Shell access with one click
5. **AI Optimization** - Get suggestions to improve Dockerfile

## ✅ Success Criteria

After Docker DX optimization, you should achieve:
- Image size: <150MB (from ~300MB baseline)
- Non-root user for security
- Multi-stage build
- Health check configured
- Minimal layers

**Enjoy exploring Docker DX! 🚀**
