#!/usr/bin/env python3
"""
Example Claude Code Skill for Coder Template Testing
Demonstrates minimal Python setup for Claude API integration
"""

import os
import sys

def check_environment():
    """Verify Claude Code environment is properly configured"""
    print("🔍 Checking Claude Code Environment...")
    print("")
    
    # Check Python version
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    print(f"✅ Python version: {python_version}")
    
    # Check user
    import getpass
    user = getpass.getuser()
    print(f"✅ Running as user: {user}")
    
    # Check working directory
    cwd = os.getcwd()
    print(f"✅ Working directory: {cwd}")
    
    # Check Anthropic library
    try:
        import anthropic
        print(f"✅ Anthropic library: {anthropic.__version__}")
    except ImportError:
        print("❌ Anthropic library not installed")
        print("   Install: pip install --user anthropic")
        return False
    
    # Check API key
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if api_key:
        print(f"✅ API key configured (length: {len(api_key)})")
    else:
        print("⚠️  ANTHROPIC_API_KEY not set")
        print("   Set: export ANTHROPIC_API_KEY='your-key-here'")
    
    print("")
    print("✅ Environment check complete!")
    return True

def simple_claude_test():
    """Simple test of Claude API (requires valid API key)"""
    try:
        import anthropic
        
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            print("⚠️  Cannot test API - ANTHROPIC_API_KEY not set")
            return
        
        print("")
        print("🤖 Testing Claude API connection...")
        
        client = anthropic.Anthropic(api_key=api_key)
        
        message = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=100,
            messages=[
                {"role": "user", "content": "Say 'Hello from UBI9-minimal container!'"}
            ]
        )
        
        print(f"✅ API Response: {message.content[0].text}")
        print("")
        
    except Exception as e:
        print(f"❌ API test failed: {e}")

def main():
    """Main entry point"""
    print("")
    print("=" * 60)
    print("UBI9-Minimal Claude Code Skill - Test Script")
    print("=" * 60)
    print("")
    
    # Environment check
    env_ok = check_environment()
    
    if not env_ok:
        print("")
        print("Please install dependencies and re-run.")
        sys.exit(1)
    
    # API test (optional - only if key is set)
    if os.getenv("ANTHROPIC_API_KEY"):
        simple_claude_test()
    else:
        print("💡 To test API integration:")
        print("   1. Set ANTHROPIC_API_KEY environment variable")
        print("   2. Run this script again")
        print("")
    
    print("✅ All checks passed!")
    print("")

if __name__ == "__main__":
    main()
