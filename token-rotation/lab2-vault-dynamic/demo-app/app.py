#!/usr/bin/env python3
"""
Demo Application: Using Vault Dynamic GitLab Secrets

This application demonstrates how to use dynamically generated GitLab tokens
from the Vault secrets plugin.

Features:
- Requests token from plugin on-demand
- Uses token for GitLab operations
- Token automatically expires after TTL
- No token storage required

Usage:
    # Set environment variables
    export PLUGIN_URL=http://localhost:5000
    export GITLAB_ROLE=test-role
    
    # Run app
    python app.py
"""

import os
import sys
import time
import logging
from datetime import datetime

try:
    import requests
    import gitlab
except ImportError:
    print("Missing dependencies. Install with: pip install requests python-gitlab")
    sys.exit(1)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class DynamicGitLabClient:
    """GitLab client that uses dynamic tokens from Vault plugin"""
    
    def __init__(self, plugin_url: str, role: str):
        self.plugin_url = plugin_url
        self.role = role
        self.current_token = None
        self.token_expires_at = None
        self.lease_id = None
        self.gitlab_client = None
    
    def get_token(self):
        """Request new token from Vault plugin"""
        try:
            logger.info(f"Requesting dynamic token for role '{self.role}'...")
            
            resp = requests.get(f'{self.plugin_url}/creds/{self.role}')
            resp.raise_for_status()
            
            data = resp.json()
            
            self.current_token = data['data']['token']
            self.lease_id = data['lease_id']
            self.token_expires_at = datetime.fromisoformat(data['data']['expires_at'])
            
            ttl = data['lease_duration']
            
            logger.info(f"✅ Received dynamic token")
            logger.info(f"   Token ID: {data['data']['token_id']}")
            logger.info(f"   Lease ID: {self.lease_id}")
            logger.info(f"   TTL: {ttl}s ({ttl//60} minutes)")
            logger.info(f"   Expires: {self.token_expires_at}")
            
            # Initialize GitLab client
            gitlab_url = data['data'].get('gitlab_url', 'https://gitlab.com')
            self.gitlab_client = gitlab.Gitlab(gitlab_url, private_token=self.current_token)
            
            return True
        
        except Exception as e:
            logger.error(f"❌ Failed to get token: {e}")
            return False
    
    def revoke_token(self):
        """Manually revoke token (normally happens automatically on expiry)"""
        if not self.lease_id:
            logger.warning("No active lease to revoke")
            return
        
        try:
            logger.info(f"Revoking lease {self.lease_id}...")
            
            resp = requests.post(f'{self.plugin_url}/revoke', 
                               json={'lease_id': self.lease_id})
            resp.raise_for_status()
            
            logger.info("✅ Token revoked successfully")
            
            self.current_token = None
            self.lease_id = None
            self.gitlab_client = None
        
        except Exception as e:
            logger.error(f"❌ Revocation failed: {e}")
    
    def perform_operations(self):
        """Demonstrate GitLab operations with dynamic token"""
        if not self.gitlab_client:
            logger.error("No GitLab client available. Get token first.")
            return False
        
        try:
            # Authenticate
            self.gitlab_client.auth()
            logger.info(f"✅ Authenticated to GitLab as {self.gitlab_client.user.username}")
            
            # List user's projects
            logger.info("\n📋 Your Projects:")
            projects = self.gitlab_client.projects.list(owned=True, per_page=5)
            for project in projects:
                logger.info(f"   - {project.path_with_namespace} (ID: {project.id})")
            
            # Get specific project (if token has access)
            try:
                # Use the project associated with the role
                # This is just for demonstration
                logger.info("\n📂 Accessing project...")
                logger.info("   (Token has limited scopes - some operations may fail)")
            except Exception as e:
                logger.warning(f"   Limited access: {e}")
            
            return True
        
        except Exception as e:
            logger.error(f"❌ GitLab operations failed: {e}")
            return False


def main():
    """Main demo flow"""
    logger.info("=" * 60)
    logger.info("Demo: Using Vault Dynamic GitLab Secrets")
    logger.info("=" * 60)
    logger.info("")
    
    # Configuration
    plugin_url = os.getenv('PLUGIN_URL', 'http://localhost:5000')
    role = os.getenv('GITLAB_ROLE', 'test-role')
    
    logger.info(f"Plugin URL: {plugin_url}")
    logger.info(f"Role: {role}")
    logger.info("")
    
    # Initialize client
    client = DynamicGitLabClient(plugin_url, role)
    
    try:
        # Step 1: Get dynamic token
        if not client.get_token():
            sys.exit(1)
        
        logger.info("")
        
        # Step 2: Use token for operations
        client.perform_operations()
        
        logger.info("")
        
        # Step 3: Demonstrate token expiry
        logger.info("💡 Token Lifecycle Demo:")
        logger.info("   In production, token expires automatically after TTL")
        logger.info("   No rotation needed - just request new token next time")
        logger.info("")
        
        # Optional: Wait and show token still works
        input("Press Enter to revoke token manually (or Ctrl+C to keep it until expiry)...")
        
        # Step 4: Manually revoke (normally automatic on expiry)
        client.revoke_token()
        
        logger.info("")
        logger.info("=" * 60)
        logger.info("✅ Demo completed successfully!")
        logger.info("=" * 60)
        logger.info("")
        logger.info("Key Takeaways:")
        logger.info("1. ✅ Tokens generated on-demand (just-in-time)")
        logger.info("2. ✅ Short-lived (minutes/hours, not days)")
        logger.info("3. ✅ Auto-revoked on expiry (zero maintenance)")
        logger.info("4. ✅ No token storage required")
        logger.info("5. ✅ Complete audit trail in Vault logs")
    
    except KeyboardInterrupt:
        logger.warning("\n⚠️ Demo cancelled by user")
        if client.lease_id:
            logger.info("Cleaning up...")
            client.revoke_token()
    
    except Exception as e:
        logger.error(f"❌ Demo failed: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
