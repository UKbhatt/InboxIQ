const express = require('express');
const cors = require('cors');
const { validateEnv, port } = require('./config/env');
const requestLogger = require('./middleware/logger');
const healthRoutes = require('./routes/healthRoutes');
const oauthRoutes = require('./routes/oauthRoutes');
const emailRoutes = require('./routes/emailRoutes');
const emailService = require('./services/emailService');

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

// Real-time email polling - check for new emails every 2 minutes
const POLL_INTERVAL_MS = 2 * 60 * 1000; // 2 minutes

async function pollForNewEmails() {
  try {
    console.log('Starting periodic email sync...');
    const userIds = await emailService.getConnectedUserIds();
    
    if (userIds.length === 0) {
      console.log('No connected users found for email sync');
      return;
    }

    console.log(`Found ${userIds.length} connected users, syncing new emails...`);
    
    // Sync new emails for each connected user
    for (const userId of userIds) {
      try {
        await emailService.syncNewEmails(userId);
      } catch (error) {
        console.error(`Error syncing emails for user ${userId}:`, error.message);
        // Continue with other users even if one fails
      }
    }
    
    console.log('Periodic email sync completed');
  } catch (error) {
    console.error('Error in periodic email sync:', error.message);
  }
}

// Start polling after a short delay (5 seconds) to let server fully start
setTimeout(() => {
  pollForNewEmails(); // Run immediately once
  setInterval(pollForNewEmails, POLL_INTERVAL_MS); // Then every 2 minutes
  console.log(`Email polling started - checking for new emails every ${POLL_INTERVAL_MS / 1000} seconds`);
}, 5000);

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

