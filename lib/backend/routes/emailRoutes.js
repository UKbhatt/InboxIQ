const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const emailController = require('../controllers/emailController');

router.get('/', verifyToken, emailController.getEmails);
router.get('/:emailId', verifyToken, emailController.getEmailById);
router.put('/:emailId/read', verifyToken, emailController.markAsRead);
router.get('/:emailId/attachments/:attachmentId', verifyToken, emailController.getAttachment);
router.post('/sync', verifyToken, emailController.startSync);
router.get('/sync/status', verifyToken, emailController.getSyncStatus);

module.exports = router;

