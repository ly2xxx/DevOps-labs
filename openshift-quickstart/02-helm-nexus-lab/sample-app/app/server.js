// Simple Node.js web server for OpenShift Helm demo

const http = require('http');
const os = require('os');

const PORT = process.env.PORT || 8080;
const ENVIRONMENT = process.env.ENVIRONMENT || 'development';
const APP_NAME = process.env.APP_NAME || 'webapp';
const VERSION = process.env.VERSION || '1.0.0';

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy' }));
    return;
  }

  if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
<!DOCTYPE html>
<html>
<head>
  <title>${APP_NAME}</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
      background: ${ENVIRONMENT === 'production' ? '#e8f5e9' : '#fff3e0'};
    }
    .card {
      background: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .env-${ENVIRONMENT} {
      color: ${ENVIRONMENT === 'production' ? '#2e7d32' : '#e65100'};
      font-weight: bold;
    }
    h1 { margin-top: 0; }
    .info { margin: 10px 0; }
    .label { color: #666; }
  </style>
</head>
<body>
  <div class="card">
    <h1>🚀 ${APP_NAME}</h1>
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
      <span class="label">Deployment:</span> Helm + Nexus Repository
    </div>
    <hr>
    <p>✅ Successfully deployed from centralized artifact repository!</p>
    <p><small>Lab 2: Helm + Nexus</small></p>
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
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${ENVIRONMENT}`);
  console.log(`App: ${APP_NAME} v${VERSION}`);
});
