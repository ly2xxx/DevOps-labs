"""
Streamlit Health Checker - Cloud Run Service
Monitors Streamlit apps and wakes sleeping instances
"""

from flask import Flask, jsonify
import requests
import logging
import os
from datetime import datetime

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Streamlit apps to monitor
# Add your apps here!
STREAMLIT_APPS = [
    "https://qr-greeting.streamlit.app",
    "https://web-player.streamlit.app",
    "https://net-test.streamlit.app"
]

@app.route('/health-check', methods=['GET', 'POST'])
def check_streamlit_health():
    """
    Check all Streamlit apps and wake sleeping ones
    
    Returns:
        JSON response with health check results
    """
    timestamp = datetime.utcnow().isoformat()
    results = []
    
    logger.info(f"Starting health check for {len(STREAMLIT_APPS)} apps...")
    
    for app_url in STREAMLIT_APPS:
        try:
            logger.info(f"Checking {app_url}...")
            response = requests.get(app_url, timeout=15)
            
            status = {
                'url': app_url,
                'status_code': response.status_code,
                'response_time_ms': int(response.elapsed.total_seconds() * 1000),
                'timestamp': timestamp
            }
            
            if response.status_code == 200:
                logger.info(f"✅ {app_url} is UP ({status['response_time_ms']}ms)")
                status['health'] = 'healthy'
            else:
                logger.warning(f"⚠️ {app_url} returned {response.status_code}")
                status['health'] = 'degraded'
            
            results.append(status)
            
        except requests.exceptions.Timeout:
            logger.error(f"❌ {app_url} - Timeout after 15s")
            results.append({
                'url': app_url,
                'health': 'timeout',
                'error': 'Request timeout after 15 seconds',
                'timestamp': timestamp
            })
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ {app_url} - Request error: {str(e)}")
            results.append({
                'url': app_url,
                'health': 'error',
                'error': f'Request error: {str(e)}',
                'timestamp': timestamp
            })
        except Exception as e:
            logger.error(f"❌ {app_url} - Unexpected error: {str(e)}")
            results.append({
                'url': app_url,
                'health': 'error',
                'error': f'Unexpected error: {str(e)}',
                'timestamp': timestamp
            })
    
    # Summary
    healthy_count = sum(1 for r in results if r.get('health') == 'healthy')
    total_count = len(results)
    
    summary = {
        'timestamp': timestamp,
        'total_apps': total_count,
        'healthy_apps': healthy_count,
        'unhealthy_apps': total_count - healthy_count,
        'success_rate': f"{(healthy_count/total_count*100):.1f}%" if total_count > 0 else "0%",
        'results': results
    }
    
    logger.info(f"Health check complete: {healthy_count}/{total_count} apps healthy")
    
    return jsonify(summary), 200

@app.route('/')
def home():
    """Root endpoint with service info"""
    info = {
        'service': 'Streamlit Health Checker',
        'version': '1.0.0',
        'monitored_apps': len(STREAMLIT_APPS),
        'endpoints': {
            'health_check': '/health-check (GET or POST)',
            'status': '/ (this page)'
        }
    }
    return jsonify(info), 200

@app.route('/status')
def status():
    """Service status endpoint"""
    return jsonify({
        'status': 'running',
        'timestamp': datetime.utcnow().isoformat()
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    logger.info(f"Starting Streamlit Health Checker on port {port}...")
    logger.info(f"Monitoring {len(STREAMLIT_APPS)} apps")
    app.run(host='0.0.0.0', port=port)
