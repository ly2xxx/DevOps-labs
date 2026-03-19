"""
Hello World - Simple Cloud Run Demo
"""

from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    """Main endpoint"""
    name = os.environ.get('NAME', 'World')
    return f'Hello {name} from Cloud Run! 🚀\n'

@app.route('/health')
def health():
    """Health check endpoint"""
    return 'OK\n', 200

if __name__ == '__main__':
    # Cloud Run sets PORT environment variable
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
