const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Docker DX!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.get('/api/info', (req, res) => {
  res.json({
    app: 'hello-docker-dx',
    version: '1.0.0',
    node: process.version,
    platform: process.platform,
    uptime: process.uptime()
  });
});

// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`✅ App listening at http://localhost:${port}`);
  console.log(`🏥 Health check: http://localhost:${port}/health`);
  console.log(`📊 Info endpoint: http://localhost:${port}/api/info`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
