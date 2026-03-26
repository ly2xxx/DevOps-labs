#!/usr/bin/env python3
"""
Test Suite for GitLab Secrets Plugin
Tests plugin functionality end-to-end

Usage:
    # Start plugin first
    python gitlab_secrets_plugin.py &
    
    # Run tests
    python test_plugin.py
"""

import os
import sys
import time
import requests
import logging

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

# Plugin endpoint
PLUGIN_URL = os.getenv('PLUGIN_URL', 'http://localhost:5000')

# Test configuration
TEST_GITLAB_URL = os.getenv('GITLAB_URL', 'https://gitlab.com')
TEST_GITLAB_TOKEN = os.getenv('GITLAB_TOKEN')  # Admin token
TEST_PROJECT_ID = os.getenv('GITLAB_PROJECT_ID')


def test_health_check():
    """Test plugin health endpoint"""
    logger.info("🔍 Testing plugin health...")
    
    try:
        resp = requests.get(f'{PLUGIN_URL}/health', timeout=5)
        resp.raise_for_status()
        
        data = resp.json()
        if data.get('status') == 'healthy':
            logger.info("✅ Plugin is healthy")
            return True
        else:
            logger.error(f"❌ Unexpected response: {data}")
            return False
    
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Health check failed: {e}")
        logger.error("   Make sure plugin is running: python gitlab_secrets_plugin.py")
        return False


def test_configure():
    """Test backend configuration"""
    logger.info("🔍 Testing backend configuration...")
    
    if not TEST_GITLAB_TOKEN or not TEST_PROJECT_ID:
        logger.warning("⚠️ Skipping: Missing GITLAB_TOKEN or GITLAB_PROJECT_ID")
        return True  # Non-critical
    
    try:
        config = {
            'gitlab_url': TEST_GITLAB_URL,
            'token': TEST_GITLAB_TOKEN,
            'default_ttl': 3600,
            'max_ttl': 86400
        }
        
        resp = requests.post(f'{PLUGIN_URL}/config', json=config)
        resp.raise_for_status()
        
        data = resp.json()
        if data['data']['configured']:
            logger.info("✅ Backend configured successfully")
            return True
        else:
            logger.error(f"❌ Configuration failed: {data}")
            return False
    
    except Exception as e:
        logger.error(f"❌ Configuration test failed: {e}")
        return False


def test_create_role():
    """Test role creation"""
    logger.info("🔍 Testing role creation...")
    
    if not TEST_PROJECT_ID:
        logger.warning("⚠️ Skipping: Missing GITLAB_PROJECT_ID")
        return True
    
    try:
        role_config = {
            'project_id': TEST_PROJECT_ID,
            'scopes': 'read_api,read_repository',
            'ttl': 1800  # 30 minutes
        }
        
        resp = requests.post(f'{PLUGIN_URL}/roles/test-role', json=role_config)
        resp.raise_for_status()
        
        data = resp.json()
        if data['data']['role_name'] == 'test-role':
            logger.info("✅ Role created successfully")
            logger.info(f"   Project: {data['data']['project_name']}")
            return True
        else:
            logger.error(f"❌ Role creation failed: {data}")
            return False
    
    except Exception as e:
        logger.error(f"❌ Role creation test failed: {e}")
        return False


def test_list_roles():
    """Test listing roles"""
    logger.info("🔍 Testing role listing...")
    
    try:
        resp = requests.get(f'{PLUGIN_URL}/roles')
        resp.raise_for_status()
        
        data = resp.json()
        roles = data['data']['keys']
        
        logger.info(f"✅ Found {len(roles)} role(s): {', '.join(roles)}")
        return True
    
    except Exception as e:
        logger.error(f"❌ Role listing failed: {e}")
        return False


def test_generate_credentials():
    """Test dynamic token generation"""
    logger.info("🔍 Testing credential generation...")
    
    if not TEST_GITLAB_TOKEN or not TEST_PROJECT_ID:
        logger.warning("⚠️ Skipping: Missing GITLAB_TOKEN or GITLAB_PROJECT_ID")
        return True
    
    try:
        resp = requests.get(f'{PLUGIN_URL}/creds/test-role')
        resp.raise_for_status()
        
        data = resp.json()
        
        # Validate response
        if 'data' in data and 'token' in data['data']:
            token = data['data']['token']
            token_id = data['data']['token_id']
            lease_id = data['lease_id']
            ttl = data['lease_duration']
            
            logger.info("✅ Credentials generated successfully")
            logger.info(f"   Token ID: {token_id}")
            logger.info(f"   Lease ID: {lease_id}")
            logger.info(f"   TTL: {ttl}s ({ttl//60} minutes)")
            logger.info(f"   Token (first 20 chars): {token[:20]}...")
            
            # Test token validity (optional)
            try:
                import gitlab
                gl = gitlab.Gitlab(TEST_GITLAB_URL, private_token=token)
                gl.auth()
                logger.info(f"   ✓ Token is valid (user: {gl.user.username})")
            except Exception as e:
                logger.warning(f"   ⚠️ Could not validate token: {e}")
            
            return True, lease_id
        else:
            logger.error(f"❌ Invalid response: {data}")
            return False, None
    
    except Exception as e:
        logger.error(f"❌ Credential generation failed: {e}")
        return False, None


def test_revoke_credentials(lease_id):
    """Test credential revocation"""
    logger.info("🔍 Testing credential revocation...")
    
    if not lease_id:
        logger.warning("⚠️ Skipping: No lease to revoke")
        return True
    
    try:
        resp = requests.post(f'{PLUGIN_URL}/revoke', json={'lease_id': lease_id})
        resp.raise_for_status()
        
        data = resp.json()
        if data['data']['revoked']:
            logger.info(f"✅ Lease revoked successfully: {lease_id}")
            return True
        else:
            logger.error(f"❌ Revocation failed: {data}")
            return False
    
    except Exception as e:
        logger.error(f"❌ Revocation test failed: {e}")
        return False


def main():
    """Run all tests"""
    logger.info("=" * 60)
    logger.info("GitLab Secrets Plugin - Test Suite")
    logger.info("=" * 60)
    logger.info("")
    
    tests = [
        ("Health Check", test_health_check, []),
        ("Configure Backend", test_configure, []),
        ("Create Role", test_create_role, []),
        ("List Roles", test_list_roles, []),
    ]
    
    results = []
    lease_id = None
    
    for test_name, test_func, args in tests:
        try:
            result = test_func(*args)
            if isinstance(result, tuple):
                result, lease_id = result
            results.append((test_name, result))
            logger.info("")
        except Exception as e:
            logger.error(f"❌ Test '{test_name}' crashed: {e}")
            results.append((test_name, False))
            logger.info("")
    
    # Test credential generation and revocation
    logger.info("🔍 Testing credential lifecycle...")
    gen_result, lease_id = test_generate_credentials()
    results.append(("Generate Credentials", gen_result))
    logger.info("")
    
    if lease_id:
        time.sleep(2)  # Brief delay
        rev_result = test_revoke_credentials(lease_id)
        results.append(("Revoke Credentials", rev_result))
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
        logger.info("✅ All tests passed! Plugin is working correctly.")
        sys.exit(0)
    else:
        logger.error("❌ Some tests failed. Check logs above.")
        sys.exit(1)


if __name__ == '__main__':
    main()
