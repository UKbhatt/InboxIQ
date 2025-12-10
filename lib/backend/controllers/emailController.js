const emailService = require('../services/emailService');

async function getEmails(req, res) {
  try {
    const limit = parseInt(req.query.limit) || 500;
    const offset = parseInt(req.query.offset) || 0;
    const type = req.query.type || 'inbox';

    const { emails, total } = await emailService.getEmails(req.user.id, { limit, offset, type });

    const formattedEmails = emails.map(email => ({
      gmail_message_id: email.gmail_message_id,
      subject: email.subject || '(No Subject)',
      from_email: email.from_email || '',
      from_name: email.from_name || '',
      snippet: email.snippet || '',
      date: email.date,
      is_read: email.is_read || false,
    }));

    res.json({
      emails: formattedEmails,
      total: total || formattedEmails.length,
    });
  } catch (error) {
    console.error('Get emails error:', error);
    res.status(500).json({ error: error.message });
  }
}

async function getEmailById(req, res) {
  try {
    const { emailId } = req.params;
    const email = await emailService.getEmailById(req.user.id, emailId);

    res.json({
      id: email.gmail_message_id,
      subject: email.subject,
      from: email.from_email,
      fromName: email.from_name,
      to: email.to_email,
      cc: email.cc,
      bcc: email.bcc,
      snippet: email.snippet,
      bodyText: email.body_text,
      bodyHtml: email.body_html,
      date: email.date,
      isRead: email.is_read,
      isStarred: email.is_starred,
      attachments: email.attachments || [],
    });
  } catch (error) {
    console.error('Get email error:', error);
    if (error.message === 'Email not found') {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: error.message });
  }
}

async function startSync(req, res) {
  try {
    const inProgress = await emailService.checkSyncInProgress(req.user.id);

    if (inProgress) {
      return res.json({ 
        message: 'Sync already in progress',
        inProgress: true 
      });
    }

    emailService.syncEmailsInBackground(req.user.id).catch(err => {
      console.error('Background sync error:', err);
    });

    res.json({ 
      message: 'Email sync started',
      inProgress: true 
    });
  } catch (error) {
    console.error('Sync start error:', error);
    res.status(500).json({ error: error.message });
  }
}

async function getSyncStatus(req, res) {
  try {
    const status = await emailService.getSyncStatus(req.user.id);
    res.json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

async function getAttachment(req, res) {
  try {
    const { emailId, attachmentId } = req.params;
    const { data, mimeType } = await emailService.getAttachment(
      req.user.id,
      emailId,
      attachmentId
    );

    res.setHeader('Content-Type', mimeType);
    res.send(data);
  } catch (error) {
    console.error('Get attachment error:', error);
    if (error.message === 'Attachment data not found' || error.message === 'Email not found') {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: error.message });
  }
}

async function markAsRead(req, res) {
  try {
    const { emailId } = req.params;
    const email = await emailService.markAsRead(req.user.id, emailId);
    res.json({ success: true, email });
  } catch (error) {
    console.error('Mark as read error:', error);
    if (error.message === 'Email not found') {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: error.message });
  }
}

module.exports = {
  getEmails,
  getEmailById,
  startSync,
  getSyncStatus,
  getAttachment,
  markAsRead,
};

