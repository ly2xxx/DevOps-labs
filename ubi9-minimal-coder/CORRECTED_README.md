# UBI9-Minimal Coder Template - CORRECTED

**⚠️ IMPORTANT CORRECTION:** Claude Code is a **Node.js package**, not Python!

---

## 🔧 What Claude Code Actually Is

**Official Package:** `@anthropic-ai/claude-code`  
**Installation:** `npm install -g @anthropic-ai/claude-code`  
**GitHub:** https://github.com/anthropics/claude-code  
**Requirements:** Node.js + npm

### The Confusion Clarified

There are TWO different Anthropic packages:

1. **`anthropic`** (Python SDK)
   - Python package for API calls
   - `pip install anthropic`
   - For building custom apps with Claude API

2. **`@anthropic-ai/claude-code`** (Claude Code CLI)
   - Node.js CLI tool
   - `npm install -g @anthropic-ai/claude-code`
   - The actual Claude Code experience

**For Coder template, you need the Node.js version!**

---

## 📦 Corrected Dockerfile Variants

### 1. **Dockerfile.with-claude-code** - Claude Code Only
```dockerfile
FROM ubi9-minimal
+ Node.js 18+
+ npm
+ @anthropic-ai/claude-code
Size: ~250MB
```

**Use when:**
- You only need Claude Code CLI
- No Python MCP servers required

---

### 2. **Dockerfile.with-both** - Complete Setup
```dockerfile
FROM ubi9-minimal
+ Node.js + npm (for Claude Code)
+ Python 3.11 (for MCP servers)
+ @anthropic-ai/claude-code
+ anthropic (Python SDK)
Size: ~280MB
```

**Use when:**
- Need Claude Code CLI
- Also running Python MCP servers
- Full development environment

---

### 3. **Dockerfile** - Python Only (Original)
```dockerfile
FROM ubi9-minimal
+ Python 3.11 + pip
Size: ~150MB
```

**Use when:**
- Building custom Python apps with Claude API
- NOT using Claude Code CLI
- MCP server development only

---

### 4. **Dockerfile.optimized** - Python Multi-Stage
```dockerfile
Stage 1: Builder
Stage 2: Runtime (Python only)
Size: ~130MB
```

**Use when:**
- Python-only optimization
- NOT using Claude Code CLI

---

## 🚀 Quick Build & Test

### Build Claude Code Version

```bash
cd C:\code\DevOps-labs\ubi9-minimal-coder

# Build with Claude Code
docker build -t coder-template:claude-code -f Dockerfile.with-claude-code .

# Test it
docker run -it --rm coder-template:claude-code

# Inside container:
claude-code --version
node --version
npm --version
```

---

### Build Complete Version (Claude Code + Python)

```bash
# Build complete setup
docker build -t coder-template:complete -f Dockerfile.with-both .

# Test it
docker run -it --rm coder-template:complete

# Inside container:
claude-code --version  # Node.js CLI
python3 --version      # For MCP servers
```

---

## 📊 Size Comparison (CORRECTED)

| Variant | Size | Contents | Use Case |
|---------|------|----------|----------|
| **Basic** | ~150MB | Python only | Python MCP dev |
| **Optimized** | ~130MB | Python (multi-stage) | Python production |
| **Claude Code** | ~250MB | Node.js + Claude Code | Claude Code CLI |
| **Complete** | ~280MB | Node.js + Python + both | Full environment |

### Why the Size Increase?

Node.js adds ~100MB to the base image:
- **UBI9-minimal:** ~100MB
- **+ Node.js runtime:** +80MB
- **+ npm packages:** +20MB
- **+ Claude Code:** +50MB

**Still better than UBI8 bloated (~380MB)!**

---

## 🎯 Which Dockerfile Should You Use?

### For Coder Claude Code Skill Hosting
```bash
# Use the complete version (most common)
docker build -t coder-template:complete -f Dockerfile.with-both .
```

**Includes:**
- ✅ Claude Code CLI (`@anthropic-ai/claude-code`)
- ✅ Python for MCP servers
- ✅ Both npm and pip available

---

### For Pure Python MCP Development
```bash
# Use basic or optimized
docker build -t coder-template:python -f Dockerfile .
```

**Includes:**
- ✅ Python 3.11
- ✅ pip for package management
- ❌ No Claude Code CLI (don't need Node.js)

---

## 🧪 Test Claude Code Installation

```bash
# Run the complete version
docker run -it --rm \
  -e ANTHROPIC_API_KEY=your-key-here \
  coder-template:complete

# Inside container:
claude-code --version
# Should show: @anthropic-ai/claude-code@X.X.X

# Test with actual API call (if key is set)
claude-code chat "Hello!"
```

---

## 📝 Updated Build Script

```powershell
# Build all four variants
.\build-all.ps1

# Results:
# - coder-template:ubi9-basic       (~150MB) - Python only
# - coder-template:ubi9-optimized   (~130MB) - Python optimized
# - coder-template:ubi9-claude      (~250MB) - Claude Code CLI
# - coder-template:ubi9-complete    (~280MB) - Complete setup
```

---

## 🔧 Installing Additional npm Packages

If you need more npm packages in the Claude Code version:

```dockerfile
# In Dockerfile.with-claude-code
USER coder

# Install Claude Code + additional packages
RUN npm install -g \
    @anthropic-ai/claude-code \
    some-other-package
```

---

## 🔧 Installing Additional Python Packages

If you need Python packages in the complete version:

```dockerfile
# In Dockerfile.with-both
RUN python3 -m pip install --user --no-cache-dir \
    anthropic \
    httpx \
    your-additional-package
```

---

## ⚠️ Key Takeaways

1. **Claude Code = Node.js package** (not Python!)
   - Install with: `npm install -g @anthropic-ai/claude-code`
   - Requires Node.js runtime

2. **For Coder skill hosting, you likely need:**
   - Node.js (for Claude Code CLI)
   - Python (for MCP servers)
   - Both npm and pip

3. **Use `Dockerfile.with-both`** for complete Coder setup

4. **Size trade-off:**
   - Python-only: ~150MB
   - Complete (Node + Python): ~280MB
   - Still 26% smaller than UBI8 bloated (~380MB)

---

## 🚀 Recommended Next Steps

1. **Build the complete version:**
   ```bash
   docker build -t coder-template:complete -f Dockerfile.with-both .
   ```

2. **Test Claude Code CLI:**
   ```bash
   docker run -it --rm coder-template:complete
   claude-code --version
   ```

3. **Deploy to Coder platform:**
   - Tag for registry
   - Push to Barclays registry
   - Update Coder template config

4. **Share with William Burton:**
   - Complete version (~280MB)
   - Still 26% reduction vs UBI8
   - Includes all necessary tools

---

## 📞 Questions?

- **Need Python only?** Use `Dockerfile` or `Dockerfile.optimized`
- **Need Claude Code CLI?** Use `Dockerfile.with-claude-code`
- **Need both?** Use `Dockerfile.with-both` (recommended for Coder)

**Great catch on the npm requirement! 🎯**
