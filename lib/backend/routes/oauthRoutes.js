const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const oauthController = require('../controllers/oauthController');

router.get('/connect', verifyToken, oauthController.generateAuthUrl);
router.get('/callback', oauthController.handleCallback);
router.post('/verify', verifyToken, oauthController.verifyCode);
router.get('/connect/status', verifyToken, oauthController.getConnectionStatus);

module.exports = router;

