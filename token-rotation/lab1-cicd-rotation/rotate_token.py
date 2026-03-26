#!/usr/bin/env python3
"""
GitLab Project Token Rotation Script
Automatically rotates GitLab project access tokens and stores them in HashiCorp Vault

Features:
- Creates new GitLab project access token
- Stores token securely in Vault with metadata
- Optionally revokes old token after grace period
- Comprehensive error handling and logging
- Dry-run mode for testing

Environment Variables:
- VAULT_ADDR: Vault server URL (required)
- VAULT_TOKEN: Vault authentication token (required)
- GITLAB_URL: GitLab instance URL (default: https://gitlab.com)
- GITLAB_TOKEN: GitLab personal/project access token with 'api' scope (required)
- GITLAB_PROJECT_ID: GitLab project ID (required)
- GITLAB_TOKEN_SCOPES: Comma-separated token scopes (default: api,read_repository,write_repository)
- GITLAB_TOKEN_EXPIRY_DAYS: Token expiry in days (default: 90)
- DRY_RUN: If "true", validate but don't make changes (default: false)
- REVOKE_OLD_TOKEN: If "true", revoke old token after rotation (default: false)
"""

import os
import sys
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import json

try:
    import gitlab
    import hvac
except ImportError:
    print("❌ Missing dependencies. Install with: pip install python-gitlab hvac")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)


class TokenRotator:
    """Manages GitLab token rotation and Vault storage"""
    
    def __init__(self):
        """Initialize with environment configuration"""
        self.vault_addr = os.getenv('VAULT_ADDR')
        self.vault_token = os.getenv('VAULT_TOKEN')
        self.gitlab_url = os.getenv('GITLAB_URL', 'https://gitlab.com')
        self.gitlab_token = os.getenv('GITLAB_TOKEN')
        self.project_id = os.getenv('GITLAB_PROJECT_ID') or os.getenv('CI_PROJECT_ID')
        
        self.token_scopes = os.getenv('GITLAB_TOKEN_SCOPES', 'api,read_repository,write_repository').split(',')
        self.token_expiry_days = int(os.getenv('GITLAB_TOKEN_EXPIRY_DAYS', '90'))
        
        self.dry_run = os.getenv('DRY_RUN', 'false').lower() == 'true'
        self.revoke_old = os.getenv('REVOKE_OLD_TOKEN', 'false').lower() == 'true'
        
        self.vault_path = f'gitlab/tokens/{self.project_id}'
        
        self._validate_config()
    
    def _validate_config(self):
        """Validate required configuration"""
        required = {
            'VAULT_ADDR': self.vault_addr,
            'VAULT_TOKEN': self.vault_token,
            'GITLAB_TOKEN': self.gitlab_token,
            'PROJECT_ID': self.project_id
        }
        
        missing = [k for k, v in required.items() if not v]
        if missing:
            raise ValueError(f"❌ Missing required environment variables: {', '.join(missing)}")
        
        logger.info("✅ Configuration validated")
        logger.info(f"   Vault: {self.vault_addr}")
        logger.info(f"   GitLab: {self.gitlab_url}")
        logger.info(f"   Project ID: {self.project_id}")
        logger.info(f"   Token scopes: {', '.join(self.token_scopes)}")
        logger.info(f"   Token expiry: {self.token_expiry_days} days")
        logger.info(f"   Dry run: {self.dry_run}")
        logger.info(f"   Revoke old: {self.revoke_old}")
    
    def connect_vault(self) -> hvac.Client:
        """Connect to Vault and verify authentication"""
        try:
            client = hvac.Client(url=self.vault_addr, token=self.vault_token)
            
            if not client.is_authenticated():
                raise Exception("Vault authentication failed")
            
            logger.info("✅ Connected to Vault")
            return client
        
        except Exception as e:
            logger.error(f"❌ Failed to connect to Vault: {e}")
            raise
    
    def connect_gitlab(self) -> gitlab.Gitlab:
        """Connect to GitLab and verify authentication"""
        try:
            gl = gitlab.Gitlab(self.gitlab_url, private_token=self.gitlab_token)
            gl.auth()
            
            logger.info(f"✅ Connected to GitLab (user: {gl.user.username})")
            return gl
        
        except Exception as e:
            logger.error(f"❌ Failed to connect to GitLab: {e}")
            raise
    
    def get_old_token_metadata(self, vault_client: hvac.Client) -> Optional[Dict[str, Any]]:
        """Retrieve metadata of existing token from Vault"""
        try:
            secret = vault_client.secrets.kv.v2.read_secret_version(path=self.vault_path)
            metadata = secret['data']['data']
            
            logger.info(f"📋 Found existing token in Vault:")
            logger.info(f"   Token ID: {metadata.get('token_id')}")
            logger.info(f"   Created: {metadata.get('created_at')}")
            logger.info(f"   Expires: {metadata.get('expires_at')}")
            
            return metadata
        
        except hvac.exceptions.InvalidPath:
            logger.info("ℹ️ No existing token found in Vault (first run)")
            return None
        
        except Exception as e:
            logger.warning(f"⚠️ Could not read existing token from Vault: {e}")
            return None
    
    def create_new_token(self, project) -> gitlab.v4.objects.ProjectAccessToken:
        """Create new GitLab project access token"""
        token_name = f"auto-rotated-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        expires_at = (datetime.now() + timedelta(days=self.token_expiry_days)).strftime('%Y-%m-%d')
        
        if self.dry_run:
            logger.info(f"🔍 [DRY RUN] Would create token:")
            logger.info(f"   Name: {token_name}")
            logger.info(f"   Scopes: {', '.join(self.token_scopes)}")
            logger.info(f"   Expires: {expires_at}")
            return None
        
        try:
            new_token = project.access_tokens.create({
                'name': token_name,
                'scopes': self.token_scopes,
                'expires_at': expires_at
            })
            
            logger.info(f"✅ Created new GitLab token: {new_token.id}")
            logger.info(f"   Name: {new_token.name}")
            logger.info(f"   Scopes: {', '.join(new_token.scopes)}")
            logger.info(f"   Expires: {new_token.expires_at}")
            
            return new_token
        
        except Exception as e:
            logger.error(f"❌ Failed to create new token: {e}")
            raise
    
    def store_in_vault(self, vault_client: hvac.Client, token_data: Dict[str, Any], old_metadata: Optional[Dict] = None):
        """Store new token in Vault with metadata"""
        if self.dry_run:
            logger.info(f"🔍 [DRY RUN] Would store token in Vault at: secret/{self.vault_path}")
            return
        
        try:
            # Add rotation metadata
            token_data.update({
                'rotated_at': datetime.now().isoformat(),
                'rotated_by': os.getenv('CI_PIPELINE_URL', 'manual'),
                'previous_token_id': old_metadata.get('token_id') if old_metadata else None,
                'rotation_count': (old_metadata.get('rotation_count', 0) + 1) if old_metadata else 1
            })
            
            vault_client.secrets.kv.v2.create_or_update_secret(
                path=self.vault_path,
                secret=token_data
            )
            
            logger.info(f"✅ Stored new token in Vault at secret/{self.vault_path}")
            logger.info(f"   Rotation count: {token_data['rotation_count']}")
        
        except Exception as e:
            logger.error(f"❌ Failed to store token in Vault: {e}")
            raise
    
    def revoke_old_token(self, project, old_token_id: Optional[str]):
        """Revoke old GitLab token"""
        if not old_token_id:
            logger.info("ℹ️ No old token to revoke")
            return
        
        if not self.revoke_old:
            logger.info(f"ℹ️ Old token {old_token_id} NOT revoked (REVOKE_OLD_TOKEN=false)")
            return
        
        if self.dry_run:
            logger.info(f"🔍 [DRY RUN] Would revoke old token: {old_token_id}")
            return
        
        try:
            project.access_tokens.delete(old_token_id)
            logger.info(f"✅ Revoked old token: {old_token_id}")
        
        except Exception as e:
            logger.warning(f"⚠️ Could not revoke old token {old_token_id}: {e}")
            logger.warning("   You may need to manually delete it from GitLab UI")
    
    def rotate(self) -> bool:
        """Main rotation workflow"""
        try:
            logger.info("=" * 60)
            logger.info("🔄 Starting GitLab token rotation")
            logger.info("=" * 60)
            
            # Connect to services
            vault_client = self.connect_vault()
            gl = self.connect_gitlab()
            project = gl.projects.get(self.project_id)
            
            # Get existing token metadata
            old_metadata = self.get_old_token_metadata(vault_client)
            
            # Create new token
            new_token = self.create_new_token(project)
            
            if not self.dry_run:
                # Prepare token data for Vault
                token_data = {
                    'token': new_token.token,
                    'token_id': new_token.id,
                    'token_name': new_token.name,
                    'scopes': ','.join(new_token.scopes),
                    'created_at': datetime.now().isoformat(),
                    'expires_at': new_token.expires_at,
                    'project_id': self.project_id,
                    'gitlab_url': self.gitlab_url
                }
                
                # Store in Vault
                self.store_in_vault(vault_client, token_data, old_metadata)
                
                # Revoke old token (if configured)
                old_token_id = old_metadata.get('token_id') if old_metadata else None
                self.revoke_old_token(project, old_token_id)
            
            logger.info("=" * 60)
            logger.info("✅ Token rotation completed successfully!")
            logger.info("=" * 60)
            
            if self.dry_run:
                logger.info("ℹ️ DRY RUN mode - no changes were made")
            
            return True
        
        except Exception as e:
            logger.error("=" * 60)
            logger.error(f"❌ Token rotation FAILED: {e}")
            logger.error("=" * 60)
            return False


def main():
    """Main entry point"""
    try:
        rotator = TokenRotator()
        success = rotator.rotate()
        sys.exit(0 if success else 1)
    
    except KeyboardInterrupt:
        logger.warning("\n⚠️ Rotation cancelled by user")
        sys.exit(130)
    
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
