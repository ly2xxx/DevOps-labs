#!/usr/bin/env python3
"""
Local Testing Script for Token Rotation
Tests Vault and GitLab connections before deploying to CI/CD

Usage:
    python test_local.py
    
Environment Variables Required:
    VAULT_ADDR, VAULT_TOKEN, GITLAB_TOKEN, GITLAB_PROJECT_ID
"""

import os
import sys
import logging
from datetime import datetime, timedelta

try:
    import gitlab
    import hvac
except ImportError:
    print("❌ Missing dependencies. Install with: pip install -r requirements.txt")
    sys.exit(1)

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)


def test_vault_connection():
    """Test Vault connection and authentication"""
    logger.info("🔍 Testing Vault connection...")
    
    vault_addr = os.getenv('VAULT_ADDR')
    vault_token = os.getenv('VAULT_TOKEN')
    
    if not vault_addr or not vault_token:
        logger.error("❌ Missing VAULT_ADDR or VAULT_TOKEN environment variables")
        return False
    
    try:
        client = hvac.Client(url=vault_addr, token=vault_token)
        
        if not client.is_authenticated():
            logger.error("❌ Vault authentication failed")
            return False
        
        # Test KV v2 access
        try:
            client.secrets.kv.v2.list_secrets(path='gitlab/tokens')
        except hvac.exceptions.InvalidPath:
            logger.info("   (No existing secrets - this is OK for first run)")
        except hvac.exceptions.Forbidden:
            logger.error("❌ Vault token lacks permissions for secret/gitlab/tokens/")
            return False
        
        logger.info("✅ Vault connection successful")
        logger.info(f"   Address: {vault_addr}")
        return True
    
    except Exception as e:
        logger.error(f"❌ Vault connection failed: {e}")
        return False


def test_gitlab_connection():
    """Test GitLab connection and project access"""
    logger.info("🔍 Testing GitLab connection...")
    
    gitlab_token = os.getenv('GITLAB_TOKEN')
    project_id = os.getenv('GITLAB_PROJECT_ID')
    gitlab_url = os.getenv('GITLAB_URL', 'https://gitlab.com')
    
    if not gitlab_token or not project_id:
        logger.error("❌ Missing GITLAB_TOKEN or GITLAB_PROJECT_ID environment variables")
        return False
    
    try:
        gl = gitlab.Gitlab(gitlab_url, private_token=gitlab_token)
        gl.auth()
        
        logger.info(f"   Authenticated as: {gl.user.username}")
        
        # Test project access
        project = gl.projects.get(project_id)
        logger.info(f"   Project: {project.name} ({project.path_with_namespace})")
        
        # Check if token has required permissions
        try:
            project.access_tokens.list()
            logger.info("   ✓ Can list access tokens")
        except Exception:
            logger.error("❌ Token lacks 'api' scope or project permissions")
            return False
        
        logger.info("✅ GitLab connection successful")
        return True
    
    except Exception as e:
        logger.error(f"❌ GitLab connection failed: {e}")
        return False


def test_token_creation():
    """Test token creation (dry run)"""
    logger.info("🔍 Testing token creation (dry run)...")
    
    try:
        gl = gitlab.Gitlab(os.getenv('GITLAB_URL', 'https://gitlab.com'), 
                          private_token=os.getenv('GITLAB_TOKEN'))
        gl.auth()
        project = gl.projects.get(os.getenv('GITLAB_PROJECT_ID'))
        
        # Get current token count
        current_tokens = project.access_tokens.list()
        logger.info(f"   Current active tokens: {len(current_tokens)}")
        
        # Check if we can create more (GitLab limit is usually 10)
        if len(current_tokens) >= 9:
            logger.warning("⚠️ Project has many active tokens. Consider cleaning up old ones.")
        
        logger.info("✅ Token creation test passed (dry run)")
        return True
    
    except Exception as e:
        logger.error(f"❌ Token creation test failed: {e}")
        return False


def test_vault_storage():
    """Test Vault secret storage"""
    logger.info("🔍 Testing Vault storage...")
    
    try:
        client = hvac.Client(url=os.getenv('VAULT_ADDR'), token=os.getenv('VAULT_TOKEN'))
        test_path = f"gitlab/tokens/test-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # Write test secret
        test_data = {
            'test': 'value',
            'timestamp': datetime.now().isoformat()
        }
        
        client.secrets.kv.v2.create_or_update_secret(
            path=test_path,
            secret=test_data
        )
        logger.info(f"   ✓ Created test secret at secret/{test_path}")
        
        # Read it back
        secret = client.secrets.kv.v2.read_secret_version(path=test_path)
        if secret['data']['data']['test'] == 'value':
            logger.info("   ✓ Read test secret successfully")
        else:
            logger.error("❌ Secret read/write mismatch")
            return False
        
        # Delete test secret
        client.secrets.kv.v2.delete_metadata_and_all_versions(path=test_path)
        logger.info("   ✓ Deleted test secret")
        
        logger.info("✅ Vault storage test passed")
        return True
    
    except Exception as e:
        logger.error(f"❌ Vault storage test failed: {e}")
        return False


def cleanup_test_data():
    """Clean up any test data"""
    logger.info("🔍 Cleaning up test data...")
    
    try:
        client = hvac.Client(url=os.getenv('VAULT_ADDR'), token=os.getenv('VAULT_TOKEN'))
        
        # List and delete any test secrets
        try:
            secrets = client.secrets.kv.v2.list_secrets(path='gitlab/tokens')
            test_secrets = [s for s in secrets['data']['keys'] if s.startswith('test-')]
            
            for test_secret in test_secrets:
                path = f"gitlab/tokens/{test_secret}"
                client.secrets.kv.v2.delete_metadata_and_all_versions(path=path)
                logger.info(f"   Deleted test secret: {path}")
        
        except hvac.exceptions.InvalidPath:
            pass  # No secrets to clean
        
        logger.info("✅ Cleanup complete")
        return True
    
    except Exception as e:
        logger.warning(f"⚠️ Cleanup warning: {e}")
        return True  # Non-critical


def main():
    """Run all tests"""
    logger.info("=" * 60)
    logger.info("GitLab Token Rotation - Local Test Suite")
    logger.info("=" * 60)
    logger.info("")
    
    tests = [
        ("Vault Connection", test_vault_connection),
        ("GitLab Connection", test_gitlab_connection),
        ("Token Creation", test_token_creation),
        ("Vault Storage", test_vault_storage),
        ("Cleanup", cleanup_test_data)
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
            logger.info("")
        except Exception as e:
            logger.error(f"❌ Test '{test_name}' crashed: {e}")
            results.append((test_name, False))
            logger.info("")
    
    # Summary
    logger.info("=" * 60)
    logger.info("Test Summary:")
    logger.info("=" * 60)
    
    all_passed = True
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        logger.info(f"{status} - {test_name}")
        if not result:
            all_passed = False
    
    logger.info("=" * 60)
    
    if all_passed:
        logger.info("✅ All tests passed! Ready for production.")
        logger.info("")
        logger.info("Next steps:")
        logger.info("1. Push code to GitLab repository")
        logger.info("2. Configure CI/CD variables in GitLab")
        logger.info("3. Run manual pipeline to test")
        logger.info("4. Set up scheduled pipeline for automatic rotation")
        sys.exit(0)
    else:
        logger.error("❌ Some tests failed. Fix issues before deploying.")
        sys.exit(1)


if __name__ == '__main__':
    main()
