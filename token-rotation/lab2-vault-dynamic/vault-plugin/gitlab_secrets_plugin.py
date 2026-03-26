#!/usr/bin/env python3
"""
GitLab Secrets Backend for HashiCorp Vault (Simplified Implementation)

This is a simplified Python implementation that demonstrates the dynamic secrets pattern.
In production, use Vault's official plugin SDK (Go-based) or community plugins.

This implementation provides:
- Backend configuration (GitLab admin credentials)
- Role management (define token properties)
- Dynamic token generation
- Automatic revocation

Usage:
    1. Configure backend: Store GitLab admin token
    2. Create roles: Define token scopes, TTL per use-case
    3. Generate tokens: Request credentials for a role
    4. Automatic cleanup: Tokens revoked on lease expiry
"""

import os
import sys
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from pathlib import Path

try:
    import gitlab
    from flask import Flask, request, jsonify
except ImportError:
    print("Missing dependencies. Install with: pip install python-gitlab flask")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('gitlab-secrets-plugin')

# Flask app for HTTP backend
app = Flask(__name__)

# In-memory storage (use Vault's encrypted storage in production)
CONFIG_STORE = {}
ROLE_STORE = {}
LEASE_STORE = {}  # Track active leases for revocation


class GitLabSecretsBackend:
    """GitLab dynamic secrets backend implementation"""
    
    def __init__(self):
        self.gitlab_url = None
        self.admin_token = None
        self.default_ttl = 3600  # 1 hour
        self.max_ttl = 86400  # 24 hours
    
    def configure(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Configure backend with GitLab admin credentials"""
        try:
            self.gitlab_url = config.get('gitlab_url', 'https://gitlab.com')
            self.admin_token = config.get('token')
            self.default_ttl = int(config.get('default_ttl', 3600))
            self.max_ttl = int(config.get('max_ttl', 86400))
            
            if not self.admin_token:
                return {'error': 'Missing required field: token'}
            
            # Validate admin token
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
            
            logger.info(f"Backend configured for {self.gitlab_url} as {gl.user.username}")
            
            return {
                'data': {
                    'gitlab_url': self.gitlab_url,
                    'default_ttl': self.default_ttl,
                    'max_ttl': self.max_ttl,
                    'configured': True
                }
            }
        
        except Exception as e:
            logger.error(f"Configuration failed: {e}")
            return {'error': str(e)}
    
    def create_role(self, role_name: str, role_config: Dict[str, Any]) -> Dict[str, Any]:
        """Create role definition"""
        try:
            project_id = role_config.get('project_id')
            scopes = role_config.get('scopes', 'read_api').split(',')
            ttl = int(role_config.get('ttl', self.default_ttl))
            
            if not project_id:
                return {'error': 'Missing required field: project_id'}
            
            # Validate project exists
            gl = gitlab.Gitlab(CONFIG_STORE.get('gitlab_url'), 
                              private_token=CONFIG_STORE.get('token'))
            try:
                project = gl.projects.get(project_id)
                project_name = project.name
            except Exception as e:
                return {'error': f'Invalid project_id: {e}'}
            
            # Store role
            ROLE_STORE[role_name] = {
                'project_id': project_id,
                'project_name': project_name,
                'scopes': scopes,
                'ttl': ttl,
                'created_at': datetime.now().isoformat()
            }
            
            logger.info(f"Created role '{role_name}' for project {project_id}")
            
            return {
                'data': {
                    'role_name': role_name,
                    'project_id': project_id,
                    'project_name': project_name,
                    'scopes': scopes,
                    'ttl': ttl
                }
            }
        
        except Exception as e:
            logger.error(f"Role creation failed: {e}")
            return {'error': str(e)}
    
    def generate_credentials(self, role_name: str) -> Dict[str, Any]:
        """Generate dynamic GitLab token for role"""
        try:
            # Get role config
            role_config = ROLE_STORE.get(role_name)
            if not role_config:
                return {'error': f"Role '{role_name}' not found"}
            
            # Get backend config
            gitlab_url = CONFIG_STORE.get('gitlab_url')
            admin_token = CONFIG_STORE.get('token')
            
            if not admin_token:
                return {'error': 'Backend not configured'}
            
            # Connect to GitLab
            gl = gitlab.Gitlab(gitlab_url, private_token=admin_token)
            project = gl.projects.get(role_config['project_id'])
            
            # Calculate expiry
            ttl_seconds = role_config['ttl']
            expires_at = datetime.now() + timedelta(seconds=ttl_seconds)
            
            # Create token
            token_name = f"vault-dynamic-{role_name}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            new_token = project.access_tokens.create({
                'name': token_name,
                'scopes': role_config['scopes'],
                'expires_at': expires_at.strftime('%Y-%m-%d')
            })
            
            # Generate lease ID
            lease_id = f"gitlab/creds/{role_name}/{new_token.id}"
            
            # Store lease for revocation
            LEASE_STORE[lease_id] = {
                'token_id': new_token.id,
                'project_id': role_config['project_id'],
                'role_name': role_name,
                'created_at': datetime.now().isoformat(),
                'expires_at': expires_at.isoformat(),
                'ttl': ttl_seconds
            }
            
            logger.info(f"Generated token {new_token.id} for role '{role_name}' (TTL: {ttl_seconds}s)")
            
            return {
                'lease_id': lease_id,
                'lease_duration': ttl_seconds,
                'lease_renewable': True,
                'data': {
                    'token': new_token.token,
                    'token_id': new_token.id,
                    'token_name': token_name,
                    'scopes': ','.join(new_token.scopes),
                    'expires_at': new_token.expires_at,
                    'project_id': role_config['project_id'],
                    'project_name': role_config['project_name']
                }
            }
        
        except Exception as e:
            logger.error(f"Credential generation failed: {e}")
            return {'error': str(e)}
    
    def revoke_credentials(self, lease_id: str) -> Dict[str, Any]:
        """Revoke dynamic token"""
        try:
            # Get lease info
            lease_info = LEASE_STORE.get(lease_id)
            if not lease_info:
                return {'error': f"Lease '{lease_id}' not found"}
            
            # Get backend config
            gitlab_url = CONFIG_STORE.get('gitlab_url')
            admin_token = CONFIG_STORE.get('token')
            
            # Connect to GitLab
            gl = gitlab.Gitlab(gitlab_url, private_token=admin_token)
            project = gl.projects.get(lease_info['project_id'])
            
            # Delete token
            try:
                project.access_tokens.delete(lease_info['token_id'])
                logger.info(f"Revoked token {lease_info['token_id']} for lease {lease_id}")
            except Exception as e:
                logger.warning(f"Token {lease_info['token_id']} may already be deleted: {e}")
            
            # Remove lease
            del LEASE_STORE[lease_id]
            
            return {
                'data': {
                    'revoked': True,
                    'token_id': lease_info['token_id'],
                    'lease_id': lease_id
                }
            }
        
        except Exception as e:
            logger.error(f"Revocation failed: {e}")
            return {'error': str(e)}
    
    def list_roles(self) -> Dict[str, Any]:
        """List all roles"""
        return {
            'data': {
                'keys': list(ROLE_STORE.keys())
            }
        }
    
    def get_role(self, role_name: str) -> Dict[str, Any]:
        """Get role configuration"""
        role_config = ROLE_STORE.get(role_name)
        if not role_config:
            return {'error': f"Role '{role_name}' not found"}
        
        return {'data': role_config}


# Initialize backend
backend = GitLabSecretsBackend()


# ==================== HTTP API Endpoints ====================

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'plugin': 'gitlab-secrets'})


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
    """Get backend configuration"""
    if not CONFIG_STORE:
        return jsonify({'error': 'Backend not configured'}), 404
    
    # Don't expose admin token
    config = CONFIG_STORE.copy()
    config['token'] = '***REDACTED***'
    return jsonify({'data': config})


@app.route('/roles/<role_name>', methods=['POST'])
def create_role_endpoint(role_name):
    """Create role"""
    role_config = request.get_json()
    result = backend.create_role(role_name, role_config)
    
    if 'error' in result:
        return jsonify(result), 400
    return jsonify(result)


@app.route('/roles/<role_name>', methods=['GET'])
def get_role_endpoint(role_name):
    """Get role configuration"""
    result = backend.get_role(role_name)
    
    if 'error' in result:
        return jsonify(result), 404
    return jsonify(result)


@app.route('/roles', methods=['GET'])
def list_roles_endpoint():
    """List roles"""
    return jsonify(backend.list_roles())


@app.route('/creds/<role_name>', methods=['GET'])
def generate_credentials_endpoint(role_name):
    """Generate dynamic credentials"""
    result = backend.generate_credentials(role_name)
    
    if 'error' in result:
        return jsonify(result), 400
    return jsonify(result)


@app.route('/revoke', methods=['POST'])
def revoke_endpoint():
    """Revoke lease"""
    data = request.get_json()
    lease_id = data.get('lease_id')
    
    if not lease_id:
        return jsonify({'error': 'Missing lease_id'}), 400
    
    result = backend.revoke_credentials(lease_id)
    
    if 'error' in result:
        return jsonify(result), 400
    return jsonify(result)


@app.route('/leases', methods=['GET'])
def list_leases_endpoint():
    """List active leases"""
    return jsonify({
        'data': {
            'keys': list(LEASE_STORE.keys()),
            'count': len(LEASE_STORE)
        }
    })


if __name__ == '__main__':
    port = int(os.getenv('PLUGIN_PORT', '5000'))
    
    logger.info("=" * 60)
    logger.info("GitLab Secrets Plugin Starting")
    logger.info("=" * 60)
    logger.info(f"Listening on port {port}")
    logger.info("Endpoints:")
    logger.info("  POST   /config              - Configure backend")
    logger.info("  GET    /config              - Get configuration")
    logger.info("  POST   /roles/<name>        - Create role")
    logger.info("  GET    /roles/<name>        - Get role")
    logger.info("  GET    /roles               - List roles")
    logger.info("  GET    /creds/<role>        - Generate credentials")
    logger.info("  POST   /revoke              - Revoke lease")
    logger.info("  GET    /leases              - List active leases")
    logger.info("=" * 60)
    
    app.run(host='0.0.0.0', port=port, debug=False)
