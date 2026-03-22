// Simple Node.js web server for OpenShift ArgoCD/GitOps demo

const http = require('http');
const os = require('os');

const PORT = process.env.PORT || 8080;
const ENVIRONMENT = process.env.ENVIRONMENT || 'development';
const APP_NAME = process.env.APP_NAME || 'webapp';
const VERSION = process.env.VERSION || '1.0.0';

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', gitops: true }));
    return;
  }

  if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
<!DOCTYPE html>
<html>
<head>
  <title>${APP_NAME} - GitOps</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .card {
      background: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .gitops-badge {
      background: #764ba2;
      color: white;
      padding: 5px 15px;
      border-radius: 20px;
      display: inline-block;
      margin: 10px 0;
      font-size: 14px;
    }
    .env-${ENVIRONMENT} {
      color: ${ENVIRONMENT === 'production' ? '#2e7d32' : '#e65100'};
      font-weight: bold;
      font-size: 20px;
    }
    h1 { margin-top: 0; color: #764ba2; }
    .info { margin: 10px 0; padding: 8px; background: #f5f5f5; border-radius: 4px; }
    .label { color: #666; font-weight: bold; }
    .emoji { font-size: 24px; }
    .git-flow {
      background: #f0f4ff;
      padding: 15px;
      border-left: 4px solid #667eea;
      margin: 20px 0;
      border-radius: 4px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1><span class="emoji">🔄</span> ${APP_NAME}</h1>
    <span class="gitops-badge">GitOps Enabled</span>
    
    <div class="info">
      <span class="label">Environment:</span> 
      <span class="env-${ENVIRONMENT}">${ENVIRONMENT.toUpperCase()}</span>
    </div>
    <div class="info">
      <span class="label">Version:</span> ${VERSION}
    </div>
    <div class="info">
      <span class="label">Hostname:</span> ${os.hostname()}
    </div>
    <div class="info">
      <span class="label">Deployment Method:</span> Helm + ArgoCD (GitOps)
    </div>
    
    <div class="git-flow">
      <strong>🎯 GitOps Flow:</strong><br>
      Git Commit → ArgoCD Detects → Auto-Deploy → Self-Heal
      <br><br>
      ✅ Source of Truth: Git Repository<br>
      ✅ Automatic Sync: Every 3 minutes<br>
      ✅ Drift Detection: Enabled<br>
      ✅ Self-Healing: Active
    </div>
    
    <hr>
    <p>✅ Successfully deployed via GitOps!</p>
    <p><small>Lab 3: Helm + ArgoCD</small></p>
    <p><small>Try making a change in Git and watch me auto-update! 🚀</small></p>
  </div>
</body>
</html>
    `);
    return;
  }

  res.writeHead(404);
  res.end('Not Found');
});

server.listen(PORT, () => {
  console.log(`🚀 GitOps Server running on port ${PORT}`);
  console.log(`Environment: ${ENVIRONMENT}`);
  console.log(`App: ${APP_NAME} v${VERSION}`);
  console.log(`Managed by: ArgoCD (GitOps)`);
});
