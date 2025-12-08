const express = require('express');
const cors = require('cors');
const { validateEnv, port } = require('./config/env');
const requestLogger = require('./middleware/logger');
const healthRoutes = require('./routes/healthRoutes');
const oauthRoutes = require('./routes/oauthRoutes');
const emailRoutes = require('./routes/emailRoutes');

validateEnv();

const app = express();

app.use(cors({
  origin: true,
  credentials: true,
}));
app.use(express.json());
app.use(requestLogger);

app.use('/', healthRoutes);
app.use('/api/oauth', oauthRoutes);
app.use('/api/emails', emailRoutes);

function getLocalIP() {
  const os = require('os');
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

app.listen(port, '0.0.0.0', () => {
  const localIP = getLocalIP();
  console.log(`Server running on port ${port}`);
  console.log(`Accessible at: http://localhost:${port}`);
  console.log(`Accessible at: http://${localIP}:${port}`);
  console.log(`\nFor Android Emulator, use: http://10.0.2.2:${port}`);
  console.log(`For physical device, use: http://${localIP}:${port}`);
  console.log(`\nHealth check: http://${localIP}:${port}/health`);
});

