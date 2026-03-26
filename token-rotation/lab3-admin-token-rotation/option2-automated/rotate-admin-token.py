#!/usr/bin/env python3
"""
GitLab Admin Token Auto-Rotation for Vault Plugin
Fully automated rotation with Vault sync

Features:
- Creates new GitLab personal access token
- Updates Vault backend config
- Revokes old token after grace period
- State tracking and notifications
- Dry-run mode

Usage:
    python rotate-admin-token.py [--dry-run] [--force] [--verbose]
"""

import os
import sys
import json
import logging
import argparse
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, Any

try:
    import gitlab
    import requests
except ImportError:
    print("Missing dependencies. Install with: pip install -r requirements.txt")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('rotation.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class AdminTokenRotator:
    """Manages GitLab admin token rotation and Vault synchronization"""
    
    def __init__(self, args):
        self.args = args
        
        # Configuration from environment
        self.gitlab_url = os.getenv('GITLAB_URL', 'https://gitlab.com')
        self.current_token = os.getenv('GITLAB_ADMIN_TOKEN')
        self.vault_addr = os.getenv('VAULT_ADDR')
        self.plugin_url = os.getenv('PLUGIN_URL', 'http://localhost:5000')
        self.vault_token = os.getenv('VAULT_TOKEN')
        
        self.rotation_days = int(os.getenv('ROTATION_DAYS', args.rotation_days))
        self.grace_period_hours = int(os.getenv('GRACE_PERIOD_HOURS', args.grace_period_hours))
        
        self.slack_webhook = os.getenv('SLACK_WEBHOOK_URL')
        
        self.state_file = Path(args.state_file)
        self.state = self.load_state()
        
        self._validate_config()
    
    def _validate_config(self):
        """Validate required configuration"""
        required = {
            'GITLAB_ADMIN_TOKEN': self.current_token,
            'VAULT_ADDR': self.vault_addr
        }
        
        missing = [k for k, v in required.items() if not v]
        if missing:
            raise ValueError(f"Missing required environment variables: {', '.join(missing)}")
        
        logger.info("Configuration validated")
    
    def load_state(self) -> Dict[str, Any]:
        """Load rotation state from file"""
        if not self.state_file.exists():
            logger.info("No state file found - first run")
            return {}
        
        try:
            with open(self.state_file, 'r') as f:
                state = json.load(f)
            logger.info(f"Loaded state from {self.state_file}")
            return state
        except Exception as e:
            logger.warning(f"Could not load state: {e}")
            return {}
    
    def save_state(self):
        """Save rotation state to file"""
        try:
            with open(self.state_file, 'w') as f:
                json.dump(self.state, f, indent=2, default=str)
            logger.info(f"State saved to {self.state_file}")
        except Exception as e:
            logger.error(f"Failed to save state: {e}")
    
    def should_rotate(self) -> bool:
        """Check if rotation is due"""
        if self.args.force:
            logger.info("Force flag set - rotation will proceed")
            return True
        
        if not self.state.get('last_rotation'):
            logger.info("No previous rotation found - will rotate")
            return True
        
        last_rotation = datetime.fromisoformat(self.state['last_rotation'])
        next_due = last_rotation + timedelta(days=self.rotation_days)
        
        if datetime.now() >= next_due:
            logger.info(f"Rotation due (last: {last_rotation})")
            return True
        else:
            logger.info(f"Rotation not due yet (next: {next_due})")
            return False
    
    def create_new_token(self) -> Optional[gitlab.v4.objects.PersonalAccessToken]:
        """Create new GitLab personal access token"""
        try:
            gl = gitlab.Gitlab(self.gitlab_url, private_token=self.current_token)
            user = gl.users.get('current')
            
            token_name = f"vault-admin-rotated-{datetime.now().strftime('%Y%m%d%H%M%S')}"
            expires_at = (datetime.now() + timedelta(days=90)).strftime('%Y-%m-%d')
            
            if self.args.dry_run:
                logger.info(f"[DRY RUN] Would create token: {token_name}")
                logger.info(f"   Scopes: api")
                logger.info(f"   Expires: {expires_at}")
                return None
            
            new_token = user.personal_access_tokens.create({
                'name': token_name,
                'scopes': ['api'],
                'expires_at': expires_at
            })
            
            logger.info(f"✅ Created new token: {new_token.id}")
            logger.info(f"   Name: {token_name}")
            logger.info(f"   Expires: {expires_at}")
            
            return new_token
        
        except Exception as e:
            logger.error(f"❌ Failed to create new token: {e}")
            raise
    
    def update_vault_config(self, new_token_value: str) -> bool:
        """Update Vault plugin backend configuration"""
        try:
            config = {
                'gitlab_url': self.gitlab_url,
                'token': new_token_value,
                'default_ttl': 3600,
                'max_ttl': 86400
            }
            
            if self.args.dry_run:
                logger.info("[DRY RUN] Would update Vault config:")
                logger.info(f"   URL: {self.plugin_url}/config")
                logger.info(f"   GitLab URL: {self.gitlab_url}")
                return True
            
            response = requests.post(
                f'{self.plugin_url}/config',
                json=config,
                timeout=10
            )
            
            if response.ok:
                logger.info("✅ Vault backend config updated")
                return True
            else:
                logger.error(f"❌ Vault update failed: {response.status_code}")
                logger.error(f"   Response: {response.text}")
                return False
        
        except Exception as e:
            logger.error(f"❌ Failed to update Vault: {e}")
            return False
    
    def verify_plugin(self) -> bool:
        """Verify plugin is still functional"""
        try:
            # Health check
            health = requests.get(f'{self.plugin_url}/health', timeout=5)
            if not health.ok:
                logger.error("❌ Plugin health check failed")
                return False
            
            # Config check
            config = requests.get(f'{self.plugin_url}/config', timeout=5)
            if config.ok:
                config_data = config.json()
                if config_data.get('data', {}).get('configured'):
                    logger.info("✅ Plugin verified and configured")
                    return True
            
            logger.error("❌ Plugin not properly configured")
            return False
        
        except Exception as e:
            logger.error(f"❌ Plugin verification failed: {e}")
            return False
    
    def revoke_old_token(self):
        """Revoke old token after grace period"""
        old_token_id = self.state.get('old_token_id')
        if not old_token_id:
            logger.info("No old token to revoke")
            return
        
        # Check grace period
        grace_expires = self.state.get('grace_period_expires')
        if grace_expires:
            grace_dt = datetime.fromisoformat(grace_expires)
            if datetime.now() < grace_dt:
                logger.info(f"Grace period not expired yet (until {grace_dt})")
                return
        
        if self.args.dry_run:
            logger.info(f"[DRY RUN] Would revoke old token: {old_token_id}")
            return
        
        if self.args.no_revoke:
            logger.info("--no-revoke flag set, skipping revocation")
            return
        
        try:
            gl = gitlab.Gitlab(self.gitlab_url, private_token=self.current_token)
            user = gl.users.get('current')
            
            # Find and delete old token
            for token in user.personal_access_tokens.list(all=True):
                if token.id == old_token_id:
                    token.delete()
                    logger.info(f"✅ Revoked old token: {old_token_id}")
                    
                    # Clear from state
                    self.state.pop('old_token_id', None)
                    self.state.pop('grace_period_expires', None)
                    return
            
            logger.warning(f"Old token {old_token_id} not found (may already be deleted)")
        
        except Exception as e:
            logger.error(f"❌ Failed to revoke old token: {e}")
    
    def send_notification(self, message: str, is_error: bool = False):
        """Send notification via Slack"""
        if not self.slack_webhook or not self.args.notify:
            return
        
        emoji = "❌" if is_error else "✅"
        color = "danger" if is_error else "good"
        
        payload = {
            "text": f"{emoji} Vault Admin Token Rotation",
            "attachments": [{
                "color": color,
                "text": message,
                "footer": f"Environment: {self.gitlab_url}"
            }]
        }
        
        try:
            requests.post(self.slack_webhook, json=payload, timeout=5)
            logger.info("Notification sent")
        except Exception as e:
            logger.warning(f"Failed to send notification: {e}")
    
    def rotate(self) -> bool:
        """Main rotation workflow"""
        try:
            logger.info("=" * 60)
            logger.info("GitLab Admin Token Rotation - Starting")
            logger.info("=" * 60)
            
            # Check if rotation needed
            if not self.should_rotate():
                logger.info("Rotation not needed at this time")
                return True
            
            # Create new token
            new_token = self.create_new_token()
            
            if not self.args.dry_run and new_token:
                # Update Vault
                if not self.update_vault_config(new_token.token):
                    raise Exception("Vault update failed")
                
                # Verify plugin
                if not self.verify_plugin():
                    raise Exception("Plugin verification failed")
                
                # Update state
                old_token_id = self.state.get('current_token_id')
                if old_token_id:
                    self.state['old_token_id'] = old_token_id
                    grace_expires = datetime.now() + timedelta(hours=self.grace_period_hours)
                    self.state['grace_period_expires'] = grace_expires.isoformat()
                
                self.state['current_token_id'] = new_token.id
                self.state['created_at'] = datetime.now().isoformat()
                self.state['last_rotation'] = datetime.now().isoformat()
                self.state['rotation_count'] = self.state.get('rotation_count', 0) + 1
                
                self.save_state()
                
                # Try to revoke old token
                self.revoke_old_token()
                
                # Notify success
                self.send_notification(
                    f"Admin token rotated successfully\n"
                    f"New token ID: {new_token.id}\n"
                    f"Rotation #{self.state['rotation_count']}"
                )
            
            logger.info("=" * 60)
            logger.info("✅ Rotation completed successfully")
            logger.info("=" * 60)
            
            return True
        
        except Exception as e:
            logger.error("=" * 60)
            logger.error(f"❌ Rotation FAILED: {e}")
            logger.error("=" * 60)
            
            self.send_notification(
                f"Rotation failed: {str(e)}",
                is_error=True
            )
            
            return False


def main():
    parser = argparse.ArgumentParser(description='GitLab Admin Token Auto-Rotation')
    parser.add_argument('--dry-run', action='store_true', help='Test without making changes')
    parser.add_argument('--verbose', action='store_true', help='Verbose logging')
    parser.add_argument('--force', action='store_true', help='Force rotation even if not due')
    parser.add_argument('--rotation-days', type=int, default=30, help='Rotation interval in days')
    parser.add_argument('--grace-period-hours', type=int, default=48, help='Grace period for old token')
    parser.add_argument('--no-revoke', action='store_true', help="Don't revoke old token")
    parser.add_argument('--notify', action='store_true', help='Send notifications')
    parser.add_argument('--state-file', default='rotation-state.json', help='State file path')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        rotator = AdminTokenRotator(args)
        success = rotator.rotate()
        sys.exit(0 if success else 1)
    
    except KeyboardInterrupt:
        logger.warning("\nRotation cancelled by user")
        sys.exit(130)
    
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
