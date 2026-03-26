#!/usr/bin/env python3
"""
Enhanced GitLab Secrets Plugin with Self-Rotation
Autonomous admin token rotation - no external dependencies

Features:
- All features from Lab 2 plugin
- Background worker for token age monitoring
- Automatic admin token rotation
- Self-updating configuration
- Health monitoring endpoints
- Comprehensive logging

Usage:
    python enhanced-plugin.py
    python enhanced-plugin.py --config plugin-config.yaml
"""

import os
import sys
import json
import yaml
import logging
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, Optional
from flask import Flask, request, jsonify

try:
    import gitlab
except ImportError:
    print("Missing dependencies. Install with: pip install python-gitlab flask pyyaml")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('plugin.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('enhanced-plugin')

# Flask app
app = Flask(__name__)

# Global state
CONFIG_STORE = {}
ROLE_STORE = {}
LEASE_STORE = {}
ROTATION_STATE = {}


class SelfRotatingBackend:
    """Enhanced GitLab secrets backend with self-rotation capability"""
    
    def __init__(self, config_file='plugin-config.yaml'):
        self.config_file = config_file
        self.config = self.load_config()
        
        # Backend configuration
        self.gitlab_url = None
        self.admin_token = None
        self.default_ttl = 3600
        self.max_ttl = 86400
        
        # Rotation configuration
        self.rotation_enabled = self.config.get('rotation', {}).get('enabled', True)
        self.check_interval_hours = self.config.get('rotation', {}).get('check_interval_hours', 1)
        self.rotate_after_days = self.config.get('rotation', {}).get('rotate_after_days', 80)
        self.token_expiry_days = self.config.get('rotation', {}).get('token_expiry_days', 90)
        self.grace_period_hours = self.config.get('rotation', {}).get('grace_period_hours', 48)
        
        # State file
        self.state_file = Path(self.config.get('plugin', {}).get('state_file', 'plugin-state.json'))
        self.load_state()
        
        # Background worker
        self.worker_thread = None
        self.worker_running = False
        
        # Initialize from config if provided
        gitlab_config = self.config.get('gitlab', {})
        if gitlab_config.get('admin_token'):
            self.configure({
                'gitlab_url': gitlab_config.get('url', 'https://gitlab.com'),
                'token': gitlab_config['admin_token']
            })
            
            # Start rotation worker if enabled
            if self.rotation_enabled:
                self.start_rotation_worker()
    
    def load_config(self) -> Dict:
        """Load configuration from YAML file"""
        if not os.path.exists(self.config_file):
            logger.warning(f"Config file {self.config_file} not found, using defaults")
            return {}
        
        try:
            with open(self.config_file, 'r') as f:
                config = yaml.safe_load(f)
            logger.info(f"Loaded config from {self.config_file}")
            return config
        except Exception as e:
            logger.error(f"Failed to load config: {e}")
            return {}
    
    def load_state(self):
        """Load rotation state from file"""
        if not self.state_file.exists():
            ROTATION_STATE.update({
                'token_created_at': datetime.now().isoformat(),
                'rotation_count': 0
            })
            return
        
        try:
            with open(self.state_file, 'r') as f:
                state = json.load(f)
            ROTATION_STATE.update(state)
            logger.info(f"Loaded state from {self.state_file}")
        except Exception as e:
            logger.warning(f"Could not load state: {e}")
    
    def save_state(self):
        """Save rotation state to file"""
        try:
            with open(self.state_file, 'w') as f:
                json.dump(ROTATION_STATE, f, indent=2, default=str)
            logger.debug("State saved")
        except Exception as e:
            logger.error(f"Failed to save state: {e}")
    
    def get_token_age_days(self) -> int:
        """Calculate current token age in days"""
        created_at = ROTATION_STATE.get('token_created_at')
        if not created_at:
            return 0
        
        created = datetime.fromisoformat(created_at)
        age = (datetime.now() - created).days
        return age
    
    def check_and_rotate(self):
        """Check if rotation is needed and perform it"""
        if not self.rotation_enabled:
            logger.debug("Rotation disabled in config")
            return
        
        age_days = self.get_token_age_days()
        logger.debug(f"Token age: {age_days} days (threshold: {self.rotate_after_days})")
        
        if age_days >= self.rotate_after_days:
            logger.info(f"Token rotation triggered (age: {age_days} days)")
            self.perform_rotation()
    
    def perform_rotation(self):
        """Perform admin token rotation"""
        try:
            logger.info("=" * 60)
            logger.info("Starting automatic admin token rotation")
            logger.info("=" * 60)
            
            # Create new token
            gl = gitlab.Gitlab(self.gitlab_url, private_token=self.admin_token)
            user = gl.users.get('current')
            
            token_name = f"vault-auto-{datetime.now().strftime('%Y%m%d%H%M%S')}"
            expires_at = (datetime.now() + timedelta(days=self.token_expiry_days)).strftime('%Y-%m-%d')
            
            new_token = user.personal_access_tokens.create({
                'name': token_name,
                'scopes': ['api'],
                'expires_at': expires_at
            })
            
            logger.info(f"✅ Created new admin token: {new_token.id}")
            
            # Store old token for revocation
            old_token_id = ROTATION_STATE.get('current_token_id')
            
            # Update own configuration
            self.admin_token = new_token.token
            CONFIG_STORE['token'] = new_token.token
            
            # Update state
            ROTATION_STATE['old_token_id'] = old_token_id
            ROTATION_STATE['current_token_id'] = new_token.id
            ROTATION_STATE['token_created_at'] = datetime.now().isoformat()
            ROTATION_STATE['last_rotation'] = datetime.now().isoformat()
            ROTATION_STATE['rotation_count'] = ROTATION_STATE.get('rotation_count', 0) + 1
            ROTATION_STATE['grace_period_expires'] = (
                datetime.now() + timedelta(hours=self.grace_period_hours)
            ).isoformat()
            
            self.save_state()
            
            logger.info(f"✅ Self-rotation complete (rotation #{ROTATION_STATE['rotation_count']})")
            
            # Schedule old token revocation
            self.schedule_old_token_revocation(old_token_id)
            
            logger.info("=" * 60)
        
        except Exception as e:
            logger.error(f"❌ Rotation failed: {e}")
    
    def schedule_old_token_revocation(self, old_token_id):
        """Schedule revocation of old token after grace period"""
        if not old_token_id:
            return
        
        grace_expires = ROTATION_STATE.get('grace_period_expires')
        if grace_expires:
            grace_dt = datetime.fromisoformat(grace_expires)
            if datetime.now() >= grace_dt:
                # Grace period already passed, revoke immediately
                self.revoke_old_token(old_token_id)
            else:
                # Will be revoked in next check after grace period
                logger.info(f"Old token {old_token_id} will be revoked after grace period")
    
    def revoke_old_token(self, token_id):
        """Revoke old admin token"""
        try:
            gl = gitlab.Gitlab(self.gitlab_url, private_token=self.admin_token)
            user = gl.users.get('current')
            
            for token in user.personal_access_tokens.list(all=True):
                if token.id == token_id:
                    token.delete()
                    logger.info(f"✅ Revoked old token: {token_id}")
                    ROTATION_STATE.pop('old_token_id', None)
                    ROTATION_STATE.pop('grace_period_expires', None)
                    self.save_state()
                    return
            
            logger.warning(f"Old token {token_id} not found (may already be deleted)")
        
        except Exception as e:
            logger.error(f"Failed to revoke old token: {e}")
    
    def rotation_worker(self):
        """Background worker that checks and rotates tokens"""
        logger.info("Rotation worker started")
        
        while self.worker_running:
            try:
                # Check and rotate if needed
                self.check_and_rotate()
                
                # Check for old token revocation
                old_token_id = ROTATION_STATE.get('old_token_id')
                if old_token_id:
                    grace_expires = ROTATION_STATE.get('grace_period_expires')
                    if grace_expires:
                        grace_dt = datetime.fromisoformat(grace_expires)
                        if datetime.now() >= grace_dt:
                            self.revoke_old_token(old_token_id)
                
                # Sleep until next check
                time.sleep(self.check_interval_hours * 3600)
            
            except Exception as e:
                logger.error(f"Worker error: {e}")
                time.sleep(60)  # Wait a bit before retrying
        
        logger.info("Rotation worker stopped")
    
    def start_rotation_worker(self):
        """Start background rotation worker"""
        if self.worker_thread and self.worker_thread.is_alive():
            logger.warning("Worker already running")
            return
        
        self.worker_running = True
        self.worker_thread = threading.Thread(target=self.rotation_worker, daemon=True)
        self.worker_thread.start()
        logger.info("Rotation worker thread started")
    
    def stop_rotation_worker(self):
        """Stop background rotation worker"""
        self.worker_running = False
        if self.worker_thread:
            self.worker_thread.join(timeout=5)
        logger.info("Rotation worker stopped")
    
    def configure(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Configure backend (same as Lab 2 plugin)"""
        try:
            self.gitlab_url = config.get('gitlab_url', 'https://gitlab.com')
            self.admin_token = config.get('token')
            self.default_ttl = int(config.get('default_ttl', 3600))
            self.max_ttl = int(config.get('max_ttl', 86400))
            
            if not self.admin_token:
                return {'error': 'Missing required field: token'}
            
            # Validate token
            gl = gitlab.Gitlab(self.gitlab_url, private_token=self.admin_token)
            gl.auth()
            
            # Store config
            CONFIG_STORE.update({
                'gitlab_url': self.gitlab_url,
                'token': self.admin_token,
                'default_ttl': self.default_ttl,
                'max_ttl': self.max_ttl,
                'configured_at': datetime.now().isoformat(),
                'configured_user': gl.user.username
            })
            
            # Initialize rotation state if first time
            if not ROTATION_STATE.get('token_created_at'):
                ROTATION_STATE['token_created_at'] = datetime.now().isoformat()
                self.save_state()
            
            logger.info(f"Backend configured for {self.gitlab_url} as {gl.user.username}")
            
            return {
                'data': {
                    'gitlab_url': self.gitlab_url,
                    'default_ttl': self.default_ttl,
                    'max_ttl': self.max_ttl,
                    'configured': True,
                    'auto_rotation_enabled': self.rotation_enabled
                }
            }
        
        except Exception as e:
            logger.error(f"Configuration failed: {e}")
            return {'error': str(e)}
    
    # All other methods from Lab 2 plugin (create_role, generate_credentials, etc.)
    # would go here - omitted for brevity, use Lab 2 implementation


# Initialize backend
backend = SelfRotatingBackend()


# ==================== HTTP ENDPOINTS ====================

@app.route('/health', methods=['GET'])
def health():
    """Enhanced health check with rotation info"""
    token_age = backend.get_token_age_days()
    
    return jsonify({
        'status': 'healthy',
        'plugin': 'gitlab-secrets-enhanced',
        'admin_token_age_days': token_age,
        'rotation_enabled': backend.rotation_enabled,
        'last_rotation': ROTATION_STATE.get('last_rotation'),
        'next_rotation_due': token_age >= backend.rotate_after_days
    })


@app.route('/config', methods=['POST'])
def configure():
    """Configure backend"""
    config = request.get_json()
    result = backend.configure(config)
    
    if 'error' in result:
        return jsonify(result), 400
    return jsonify(result)


@app.route('/config', methods=['GET'])
def get_config():
    """Get configuration (token redacted)"""
    if not CONFIG_STORE:
        return jsonify({'error': 'Backend not configured'}), 404
    
    config = CONFIG_STORE.copy()
    config['token'] = '***REDACTED***'
    return jsonify({'data': config})


@app.route('/rotation-status', methods=['GET'])
def rotation_status():
    """Get rotation status"""
    return jsonify({
        'enabled': backend.rotation_enabled,
        'current_token_id': ROTATION_STATE.get('current_token_id'),
        'token_age_days': backend.get_token_age_days(),
        'rotation_count': ROTATION_STATE.get('rotation_count', 0),
        'last_rotation': ROTATION_STATE.get('last_rotation'),
        'next_check_hours': backend.check_interval_hours,
        'rotate_after_days': backend.rotate_after_days,
        'worker_running': backend.worker_running
    })


@app.route('/force-rotation', methods=['POST'])
def force_rotation():
    """Force rotation (for testing)"""
    try:
        backend.perform_rotation()
        return jsonify({'success': True, 'message': 'Rotation triggered'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Add all other endpoints from Lab 2 plugin (roles, creds, etc.)


if __name__ == '__main__':
    port = int(os.getenv('PLUGIN_PORT', backend.config.get('plugin', {}).get('port', 5000)))
    
    logger.info("=" * 60)
    logger.info("Enhanced GitLab Secrets Plugin with Self-Rotation")
    logger.info("=" * 60)
    logger.info(f"Listening on port {port}")
    logger.info(f"Auto-rotation: {'ENABLED' if backend.rotation_enabled else 'DISABLED'}")
    if backend.rotation_enabled:
        logger.info(f"Check interval: {backend.check_interval_hours} hour(s)")
        logger.info(f"Rotate after: {backend.rotate_after_days} days")
        logger.info(f"Current token age: {backend.get_token_age_days()} days")
    logger.info("=" * 60)
    
    try:
        app.run(host='0.0.0.0', port=port, debug=False)
    finally:
        backend.stop_rotation_worker()
