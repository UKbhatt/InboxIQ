const { google } = require('googleapis');
const supabase = require('../config/database');
const oauthService = require('./oauthService');
const { parseEmailBody, extractAttachments, extractEmailHeaders } = require('../utils/emailParser');

const MAX_EMAILS = 500;
const EMAILS_PER_LABEL = 100;

// labels 
const LABELS_TO_SYNC = ['INBOX', 'SENT', 'DRAFT', 'TRASH', 'SPAM', 'STARRED'];

async function syncEmailsForLabel(gmail, userId, label, maxEmails) {
  let totalSynced = 0;
  let nextPageToken = null;
  let hasMore = true;

  while (hasMore && totalSynced < maxEmails) {
    const remaining = maxEmails - totalSynced;
    const batchSize = Math.min(remaining, 500);
    
    const params = {
      maxResults: batchSize,
      labelIds: [label],
    };

    if (nextPageToken) {
      params.pageToken = nextPageToken;
    }

    try {
      const response = await gmail.users.messages.list({
        userId: 'me',
        ...params,
      });

      const messages = response.data.messages || [];
      nextPageToken = response.data.nextPageToken;
      
      if (messages.length === 0) {
        hasMore = false;
        break;
      }

      const emailsToProcess = messages.slice(0, remaining);
      console.log(`[${label}] Fetching ${emailsToProcess.length} emails (${totalSynced + 1}-${totalSynced + emailsToProcess.length})...`);

      const emailPromises = emailsToProcess.map(async (message) => {
        try {
          const emailData = await gmail.users.messages.get({
            userId: 'me',
            id: message.id,
            format: 'full',
          });

          const msg = emailData.data;
          const payload = msg.payload || {};
          const headers = payload.headers || [];

          const headerData = await extractEmailHeaders(headers);
          const { bodyText, bodyHtml } = await parseEmailBody(payload);
          const attachments = extractAttachments(payload);

          const emailRecord = {
            id: `${userId}_${msg.id}`,
            user_id: userId,
            gmail_message_id: msg.id,
            thread_id: msg.threadId,
            subject: headerData.subject || '(No Subject)',
            from_email: headerData.from,
            from_name: headerData.fromName,
            to_email: headerData.to,
            cc: headerData.cc || null,
            bcc: headerData.bcc || null,
            snippet: msg.snippet || '',
            body_text: bodyText,
            body_html: bodyHtml,
            date: headerData.date.toISOString(),
            is_read: !(msg.labelIds || []).includes('UNREAD'),
            is_starred: (msg.labelIds || []).includes('STARRED'),
            label_ids: msg.labelIds || [],
            attachments: attachments,
            updated_at: new Date().toISOString(),
          };

          await supabase
            .from('emails')
            .upsert(emailRecord, {
              onConflict: 'id'
            });

          return true;
        } catch (error) {
          console.error(`[${label}] Error processing email ${message.id}:`, error.message);
          return false;
        }
      });

      const results = await Promise.all(emailPromises);
      totalSynced += results.filter(r => r).length;

      if (messages.length < batchSize || !nextPageToken) {
        hasMore = false;
      }
    } catch (error) {
      console.error(`[${label}] Error fetching messages:`, error.message);
      hasMore = false;
    }
  }

  return totalSynced;
}

async function syncEmailsInBackground(userId) {
  try {
    console.log(`Starting email sync for user: ${userId}`);
    
    await supabase
      .from('email_sync_status')
      .upsert({
        user_id: userId,
        sync_in_progress: true,
        last_sync_error: null,
        updated_at: new Date().toISOString(),
      }, {
        onConflict: 'user_id'
      });

    const accessToken = await oauthService.getValidAccessToken(userId);
    oauthService.oauth2Client.setCredentials({ access_token: accessToken });
    const gmail = google.gmail({ version: 'v1', auth: oauthService.oauth2Client });

    let totalSynced = 0;

    for (const label of LABELS_TO_SYNC) {
      try {
        console.log(`Syncing emails from ${label}...`);
        const synced = await syncEmailsForLabel(gmail, userId, label, EMAILS_PER_LABEL);
        totalSynced += synced;
        console.log(`✓ Synced ${synced} emails from ${label}`);
        
        await supabase
          .from('email_sync_status')
          .update({
            total_emails_synced: totalSynced,
            updated_at: new Date().toISOString(),
          })
          .eq('user_id', userId);
      } catch (error) {
        console.error(`Error syncing ${label}:`, error.message);
      }
    }

    await supabase
      .from('email_sync_status')
      .update({
        sync_in_progress: false,
        last_sync_at: new Date().toISOString(),
        total_emails_synced: totalSynced,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    console.log(`✓ Email sync completed for user ${userId}. Total: ${totalSynced} emails`);
  } catch (error) {
    console.error('Email sync error:', error);
    await supabase
      .from('email_sync_status')
      .update({
        sync_in_progress: false,
        last_sync_error: error.message,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);
  }
}

async function syncNewEmails(userId) {
  try {
    const syncStatus = await getSyncStatus(userId);
    const lastSyncAt = syncStatus.lastSyncAt ? new Date(syncStatus.lastSyncAt) : null;
    
    if (!lastSyncAt) {
      console.log(`No previous sync found for user ${userId}, starting full sync...`);
      await syncEmailsInBackground(userId);
      return;
    }

    const accessToken = await oauthService.getValidAccessToken(userId);
    oauthService.oauth2Client.setCredentials({ access_token: accessToken });
    const gmail = google.gmail({ version: 'v1', auth: oauthService.oauth2Client });

    const thresholdDate = new Date();
    thresholdDate.setDate(thresholdDate.getDate() - 7);
    const thresholdMs = Math.floor(thresholdDate.getTime() / 1000);

    const params = {
      maxResults: 50,
      labelIds: ['INBOX'],
      q: `after:${thresholdMs}`,
    };

    const response = await gmail.users.messages.list({
      userId: 'me',
      ...params,
    });

    const messages = response.data.messages || [];
    if (messages.length === 0) {
      console.log(`No new emails for user ${userId}`);
      return;
    }

    console.log(`Found ${messages.length} new emails for user ${userId}, syncing...`);

    let synced = 0;
    for (const message of messages) {
      try {
        const emailData = await gmail.users.messages.get({
          userId: 'me',
          id: message.id,
          format: 'full',
        });

        const msg = emailData.data;
        const payload = msg.payload || {};
        const headers = payload.headers || [];

        const headerData = await extractEmailHeaders(headers);
        const { bodyText, bodyHtml } = await parseEmailBody(payload);
        const attachments = extractAttachments(payload);

        const emailRecord = {
          id: `${userId}_${msg.id}`,
          user_id: userId,
          gmail_message_id: msg.id,
          thread_id: msg.threadId,
          subject: headerData.subject || '(No Subject)',
          from_email: headerData.from,
          from_name: headerData.fromName,
          to_email: headerData.to,
          cc: headerData.cc || null,
          bcc: headerData.bcc || null,
          snippet: msg.snippet || '',
          body_text: bodyText,
          body_html: bodyHtml,
          date: headerData.date.toISOString(),
          is_read: !(msg.labelIds || []).includes('UNREAD'),
          is_starred: (msg.labelIds || []).includes('STARRED'),
          label_ids: msg.labelIds || [],
          attachments: attachments,
          updated_at: new Date().toISOString(),
        };

        await supabase
          .from('emails')
          .upsert(emailRecord, {
            onConflict: 'id'
          });

        synced++;
      } catch (error) {
        console.error(`Error syncing new email ${message.id}:`, error.message);
      }
    }

    if (synced > 0) {
      await supabase
        .from('email_sync_status')
        .update({
          last_sync_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('user_id', userId);
      
      console.log(`✓ Synced ${synced} new emails for user ${userId}`);
    }
  } catch (error) {
    console.error('Incremental sync error:', error.message);
  }
}

async function getEmails(userId, { limit = 500, offset = 0, type = 'inbox', updatedAfter = null }) {
  let query = supabase
    .from('emails')
    .select('*', { count: 'exact' })
    .eq('user_id', userId);

  if (updatedAfter) {
    const updatedAfterDate = new Date(updatedAfter);
    query = query.gt('updated_at', updatedAfterDate.toISOString());
  }

  const labelMap = {
    'inbox': 'INBOX',
    'sent': 'SENT',
    'draft': 'DRAFT',
    'trash': 'TRASH',
    'spam': 'SPAM',
    'starred': 'STARRED',
    'unread': 'UNREAD',
  };

  const emailType = (type || 'inbox').toLowerCase();
  const targetLabel = labelMap[emailType];

  if (targetLabel) {
    if (emailType === 'unread') {
      query = query.eq('is_read', false);
    } else if (emailType === 'starred') {
      query = query.eq('is_starred', true);
    } else {

      const { data: allEmails, error: fetchError } = await supabase
        .from('emails')
        .select('*', { count: 'exact' })
        .eq('user_id', userId);
      
      if (fetchError) {
        throw new Error('Failed to fetch emails: ' + fetchError.message);
      }
      
      const filteredEmails = (allEmails || []).filter(email => 
        email.label_ids && Array.isArray(email.label_ids) && email.label_ids.includes(targetLabel)
      );
      
      filteredEmails.sort((a, b) => new Date(b.date) - new Date(a.date));
      
      const paginatedEmails = filteredEmails.slice(offset, offset + limit);
      
      return {
        emails: paginatedEmails,
        total: filteredEmails.length,
      };
    }
  }

  const { data: emails, error, count } = await query
    .order('date', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    throw new Error('Failed to fetch emails: ' + error.message);
  }

  return {
    emails: emails || [],
    total: count || 0,
  };
}

async function getEmailById(userId, emailId) {
  const { data: email, error } = await supabase
    .from('emails')
    .select('*')
    .eq('user_id', userId)
    .eq('gmail_message_id', emailId)
    .single();

  if (error || !email) {
    throw new Error('Email not found');
  }

  return email;
}

async function markAsRead(userId, emailId) {
  const { data, error } = await supabase
    .from('emails')
    .update({ is_read: true, updated_at: new Date().toISOString() })
    .eq('user_id', userId)
    .eq('gmail_message_id', emailId)
    .select()
    .single();

  if (error) {
    throw new Error('Failed to mark email as read: ' + error.message);
  }

  return data;
}

async function getSyncStatus(userId) {
  const { data, error } = await supabase
    .from('email_sync_status')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error && error.code !== 'PGRST116') {
    throw new Error('Database error');
  }

  return {
    hasSynced: !!data?.last_sync_at,
    inProgress: data?.sync_in_progress || false,
    lastSyncAt: data?.last_sync_at,
    totalEmails: data?.total_emails_synced || 0,
    lastError: data?.last_sync_error,
  };
}

async function checkSyncInProgress(userId) {
  const { data } = await supabase
    .from('email_sync_status')
    .select('sync_in_progress')
    .eq('user_id', userId)
    .single();

  return data?.sync_in_progress || false;
}

async function getConnectedUserIds() {
  try {
    const { data, error } = await supabase
      .from('oauth_tokens')
      .select('user_id');
    
    if (error) {
      console.error('Error fetching connected users:', error.message);
      return [];
    }
    
    return (data || []).map(row => row.user_id);
  } catch (error) {
    console.error('Error getting connected users:', error.message);
    return [];
  }
}

async function getAttachment(userId, emailId, attachmentId) {
  const accessToken = await oauthService.getValidAccessToken(userId);
  oauthService.oauth2Client.setCredentials({ access_token: accessToken });
  const gmail = google.gmail({ version: 'v1', auth: oauthService.oauth2Client });

  const response = await gmail.users.messages.attachments.get({
    userId: 'me',
    messageId: emailId,
    id: attachmentId,
  });

  const attachmentData = response.data.data;
  if (!attachmentData) {
    throw new Error('Attachment data not found');
  }

  const { decodeBase64Url } = require('../utils/emailParser');
  const decodedData = decodeBase64Url(attachmentData);

  const email = await getEmailById(userId, emailId);
  let mimeType = 'application/octet-stream';
  if (email && email.attachments) {
    const attachmentMeta = email.attachments.find(att => att.attachmentId === attachmentId);
    if (attachmentMeta) {
      mimeType = attachmentMeta.mimeType;
    }
  }

  return {
    data: decodedData,
    mimeType,
  };
}

module.exports = {
  syncEmailsInBackground,
  syncNewEmails,
  getEmails,
  getEmailById,
  getSyncStatus,
  checkSyncInProgress,
  getAttachment,
  markAsRead,
  getConnectedUserIds,
};

