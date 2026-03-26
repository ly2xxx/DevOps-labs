#!/bin/bash
# HashiCorp Vault GitLab Secrets Plugin - Setup Script (Linux/macOS/Git Bash)
# Automates plugin installation and registration with Vault
#
# Prerequisites:
# - Vault server running (dev or production)
# - VAULT_ADDR and VAULT_TOKEN environment variables set
# - Python 3.8+ installed
#
# Usage:
#   ./setup_plugin.sh
#   ./setup_plugin.sh --test-only    # Auto-start plugin for testing

set -e

SKIP_INSTALL=false
TEST_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-install] [--test-only]"
            exit 1
            ;;
    esac
done

echo ""
echo "====================================================================="
echo "   HashiCorp Vault GitLab Secrets Plugin - Setup"
echo "====================================================================="
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."
echo ""

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python: $PYTHON_VERSION"
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version)
    echo "✅ Python: $PYTHON_VERSION"
    PYTHON_CMD="python"
else
    echo "❌ Python not found. Install Python 3.8+ first."
    exit 1
fi

# Check pip
if command -v pip3 &> /dev/null; then
    PIP_CMD="pip3"
elif command -v pip &> /dev/null; then
    PIP_CMD="pip"
else
    echo "❌ pip not found. Install pip first."
    exit 1
fi

# Check Vault environment variables
if [ -z "$VAULT_ADDR" ]; then
    echo "❌ VAULT_ADDR not set"
    echo "   Set with: export VAULT_ADDR='http://localhost:8200'"
    exit 1
fi

if [ -z "$VAULT_TOKEN" ]; then
    echo "❌ VAULT_TOKEN not set"
    echo "   Set with: export VAULT_TOKEN='root'"
    exit 1
fi

echo "✅ VAULT_ADDR: $VAULT_ADDR"
echo "✅ VAULT_TOKEN: ***"
echo ""

# Test Vault connection
echo "🔍 Testing Vault connection..."
if command -v vault &> /dev/null; then
    if vault status &> /dev/null || [ $? -eq 2 ]; then
        echo "✅ Connected to Vault"
    else
        echo "❌ Cannot connect to Vault at $VAULT_ADDR"
        echo "   Make sure Vault is running"
        exit 1
    fi
else
    # Try with curl
    if curl -s -o /dev/null -w "%{http_code}" "$VAULT_ADDR/v1/sys/health" | grep -q "200\|429\|472\|473"; then
        echo "✅ Connected to Vault"
    else
        echo "❌ Cannot connect to Vault at $VAULT_ADDR"
        echo "   Make sure Vault is running"
        exit 1
    fi
fi
echo ""

# Install Python dependencies
if [ "$SKIP_INSTALL" = false ]; then
    echo "📦 Installing Python dependencies..."
    $PIP_CMD install -r requirements.txt --quiet
    echo "✅ Dependencies installed"
    echo ""
fi

# Note about plugin type
echo "ℹ️  This is a simplified HTTP-based plugin implementation"
echo "   For production, use Vault's official Plugin SDK (Go-based)"
echo ""

# Start plugin server (if test mode)
if [ "$TEST_ONLY" = true ]; then
    echo "🧪 Starting plugin server for testing..."
    echo ""
    
    # Start in background
    $PYTHON_CMD gitlab_secrets_plugin.py &
    PLUGIN_PID=$!
    
    echo "✅ Plugin server started (PID: $PLUGIN_PID)"
    echo "   Listening on http://localhost:5000"
    echo ""
    
    # Wait for server to start
    echo "⏳ Waiting for server to be ready..."
    sleep 3
    
    # Test plugin health
    if curl -s http://localhost:5000/health | grep -q "healthy"; then
        echo "✅ Plugin server is healthy"
    else
        echo "❌ Plugin server not responding"
        kill $PLUGIN_PID 2>/dev/null
        exit 1
    fi
    
    echo ""
    echo "====================================================================="
    echo "   Plugin Setup Complete!"
    echo "====================================================================="
    echo ""
    echo "🚀 Next Steps:"
    echo ""
    echo "1. Configure the backend:"
    echo '   curl -X POST http://localhost:5000/config -H "Content-Type: application/json" -d '"'"'{"gitlab_url":"https://gitlab.com","token":"your-gitlab-token"}'"'"''
    echo ""
    echo "2. Create a role:"
    echo '   curl -X POST http://localhost:5000/roles/test-role -H "Content-Type: application/json" -d '"'"'{"project_id":"12345","scopes":"read_api","ttl":3600}'"'"''
    echo ""
    echo "3. Generate credentials:"
    echo "   curl http://localhost:5000/creds/test-role"
    echo ""
    echo "4. Run tests:"
    echo "   python test_plugin.py"
    echo ""
    echo "Plugin PID: $PLUGIN_PID"
    echo "To stop: kill $PLUGIN_PID"
    echo ""
    echo "====================================================================="
    
    # Save PID for cleanup
    echo $PLUGIN_PID > .plugin.pid
    
else
    echo "====================================================================="
    echo "   Setup Complete!"
    echo "====================================================================="
    echo ""
    echo "🚀 Next Steps:"
    echo ""
    echo "1. Start the plugin server:"
    echo "   $PYTHON_CMD gitlab_secrets_plugin.py"
    echo ""
    echo "2. In another terminal, run tests:"
    echo "   $PYTHON_CMD test_plugin.py"
    echo ""
    echo "3. Or follow the lab guide in README.md"
    echo ""
    echo "💡 Tip: Use '--test-only' flag to auto-start plugin for testing"
    echo "   Example: ./setup_plugin.sh --test-only"
    echo ""
    echo "====================================================================="
fi
