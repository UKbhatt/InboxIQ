require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { google } = require('googleapis');
const crypto = require('crypto');

const requiredEnvVars = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'GOOGLE_CLIENT_ID',
  'GOOGLE_CLIENT_SECRET',
  'GOOGLE_REDIRECT_URI',
  'ENCRYPTION_KEY'
];

const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
if (missingVars.length > 0) {
  console.error('Missing required environment variables:', missingVars.join(', '));
  console.error('Please check your .env file in lib/backend/');
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({
  origin: true,
  credentials: true,
}));
app.use(express.json());

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID?.trim(),
  process.env.GOOGLE_CLIENT_SECRET?.trim(),
  process.env.GOOGLE_REDIRECT_URI?.trim()
);

console.log('OAuth2 Client initialized:');
console.log('  Client ID:', process.env.GOOGLE_CLIENT_ID?.trim());
console.log('  Redirect URI:', process.env.GOOGLE_REDIRECT_URI?.trim());
console.log('  Client Secret:', process.env.GOOGLE_CLIENT_SECRET ? '***' + process.env.GOOGLE_CLIENT_SECRET.slice(-4) : 'NOT SET');

const SCOPES = ['https://www.googleapis.com/auth/gmail.readonly'];

function encrypt(text) {
  const algorithm = 'aes-256-cbc';
  const key = Buffer.from(process.env.ENCRYPTION_KEY, 'hex');
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

function decrypt(encryptedText) {
  const algorithm = 'aes-256-cbc';
  const key = Buffer.from(process.env.ENCRYPTION_KEY, 'hex');
  const parts = encryptedText.split(':');
  const iv = Buffer.from(parts[0], 'hex');
  const encrypted = parts[1];
  const decipher = crypto.createDecipheriv(algorithm, key, iv);
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.error('No authorization header provided');
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const token = authHeader.split(' ')[1];
  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) {
    console.error('Token verification failed:', error?.message || 'No user');
    return res.status(401).json({ error: 'Invalid token' });
  }

  req.user = user;
  next();
}

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/oauth/connect', verifyToken, (req, res) => {
  try {
    console.log('Generating OAuth URL for user:', req.user.id);
    console.log('Redirect URI from env:', process.env.GOOGLE_REDIRECT_URI);
    console.log('Redirect URI length:', process.env.GOOGLE_REDIRECT_URI?.length);
    console.log('Redirect URI trimmed:', process.env.GOOGLE_REDIRECT_URI?.trim());
    console.log('OAuth client redirect URI:', oauth2Client.redirectUri);
    
    const redirectUri = process.env.GOOGLE_REDIRECT_URI?.trim();
    if (!redirectUri) {
      return res.status(500).json({ error: 'Redirect URI not configured' });
    }
    
    const authUrl = oauth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: SCOPES,
      state: req.user.id,
      prompt: 'consent',
      redirect_uri: redirectUri,
    });

    console.log('OAuth URL generated successfully');
    console.log('Generated OAuth URL:', authUrl);
    
    const urlObj = new URL(authUrl);
    const redirectParam = urlObj.searchParams.get('redirect_uri');
    console.log('Redirect URI in generated URL (decoded):', decodeURIComponent(redirectParam || ''));
    
    res.json({ authUrl });
  } catch (error) {
    console.error('Error generating OAuth URL:', error);
    res.status(500).json({ error: 'Failed to generate OAuth URL: ' + error.message });
  }
});

app.get('/api/oauth/callback', async (req, res) => {
  try {
    console.log('=== OAuth Callback Received ===');
    console.log('Query params:', req.query);
    console.log('Full URL:', req.url);
    
    const { code, state, error: oauthError } = req.query;
    
    if (oauthError) {
      console.error('OAuth error from Google:', oauthError);
      return res.status(400).send(`OAuth error: ${oauthError}. Check Google Cloud Console redirect URI configuration.`);
    }
    
    if (!code) {
      console.error('No authorization code received');
      return res.status(400).send('Authorization code is required');
    }

    console.log('Exchanging code for tokens...');
    const { tokens } = await oauth2Client.getToken(code);
    
    if (!tokens.refresh_token) {
      console.error('No refresh token received');
      return res.status(400).send('Refresh token not provided');
    }

    const userId = state;
    if (!userId) {
      console.error('No user ID in state parameter');
      return res.status(400).send('User ID is required');
    }

    console.log('Encrypting tokens for user:', userId);
    const encryptedRefreshToken = encrypt(tokens.refresh_token);
    const encryptedAccessToken = tokens.access_token ? encrypt(tokens.access_token) : null;

    console.log('Saving tokens to database...');
    const { error: tokenError } = await supabase
      .from('oauth_tokens')
      .upsert({
        user_id: userId,
        refresh_token: encryptedRefreshToken,
        access_token: encryptedAccessToken,
        expires_at: tokens.expiry_date ? new Date(tokens.expiry_date).toISOString() : null,
        updated_at: new Date().toISOString(),
      }, {
        onConflict: 'user_id'
      });

    if (tokenError) {
      console.error('Database error:', tokenError);
      return res.status(500).send('Failed to save tokens: ' + tokenError.message);
    }

    console.log('✓ Tokens saved successfully for user:', userId);

    const { data: syncStatus } = await supabase
      .from('email_sync_status')
      .select('last_sync_at')
      .eq('user_id', userId)
      .single();

    const isFirstTime = !syncStatus || !syncStatus.last_sync_at;

    if (isFirstTime) {
      console.log('First time user - starting email sync in background...');
      syncEmailsInBackground(userId).catch(err => {
        console.error('Background sync error:', err);
      });
    }

    res.send(`
      <html>
        <body>
          <h1>Gmail Connected Successfully!</h1>
          <p>You can close this window and return to the app.</p>
          ${isFirstTime ? '<p><strong>Email sync has started. This may take a few minutes.</strong></p>' : ''}
          <script>
            window.close();
          </script>
        </body>
      </html>
    `);
  } catch (error) {
    console.error('OAuth callback error:', error);
    res.status(500).send('Error connecting Gmail: ' + error.message);
  }
});

app.post('/api/oauth/verify', verifyToken, async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) {
      return res.status(400).json({ error: 'Code is required' });
    }

    const { tokens } = await oauth2Client.getToken(code);
    
    if (!tokens.refresh_token) {
      return res.status(400).json({ error: 'Refresh token not provided' });
    }

    const encryptedRefreshToken = encrypt(tokens.refresh_token);
    const encryptedAccessToken = tokens.access_token ? encrypt(tokens.access_token) : null;

    const { error } = await supabase
      .from('oauth_tokens')
      .upsert({
        user_id: req.user.id,
        refresh_token: encryptedRefreshToken,
        access_token: encryptedAccessToken,
        expires_at: tokens.expiry_date ? new Date(tokens.expiry_date).toISOString() : null,
        updated_at: new Date().toISOString(),
      }, {
        onConflict: 'user_id'
      });

    if (error) {
      console.error('Database error:', error);
      return res.status(500).json({ error: 'Failed to save tokens' });
    }

    res.json({ success: true });
  } catch (error) {
    console.error('OAuth verify error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/oauth/connect/status', verifyToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('oauth_tokens')
      .select('user_id')
      .eq('user_id', req.user.id)
      .single();

    if (error && error.code !== 'PGRST116') {
      return res.status(500).json({ error: 'Database error' });
    }

    res.json({ connected: !!data });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

async function getValidAccessToken(userId) {
  const { data, error } = await supabase
    .from('oauth_tokens')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error || !data) {
    throw new Error('No OAuth tokens found');
  }

  const refreshToken = decrypt(data.refresh_token);
  oauth2Client.setCredentials({
    refresh_token: refreshToken,
  });

  if (data.access_token && data.expires_at && new Date(data.expires_at) > new Date()) {
    const accessToken = decrypt(data.access_token);
    oauth2Client.setCredentials({
      refresh_token: refreshToken,
      access_token: accessToken,
    });
    return accessToken;
  }

  const { credentials } = await oauth2Client.refreshAccessToken();
  const newAccessToken = credentials.access_token;
  const encryptedAccessToken = encrypt(newAccessToken);

  await supabase
    .from('oauth_tokens')
    .update({
      access_token: encryptedAccessToken,
      expires_at: credentials.expiry_date ? new Date(credentials.expiry_date).toISOString() : null,
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId);

  return newAccessToken;
}

async function parseEmailBody(payload) {
  let bodyText = '';
  let bodyHtml = '';

  if (payload.body && payload.body.data) {
    const decoded = Buffer.from(payload.body.data, 'base64').toString('utf-8');
    if (payload.mimeType === 'text/plain') {
      bodyText = decoded;
    } else if (payload.mimeType === 'text/html') {
      bodyHtml = decoded;
    }
  }

  if (payload.parts) {
    for (const part of payload.parts) {
      if (part.mimeType === 'text/plain' && part.body && part.body.data) {
        bodyText = Buffer.from(part.body.data, 'base64').toString('utf-8');
      } else if (part.mimeType === 'text/html' && part.body && part.body.data) {
        bodyHtml = Buffer.from(part.body.data, 'base64').toString('utf-8');
      }
      
      if (part.parts) {
        const nested = await parseEmailBody(part);
        if (nested.bodyText) bodyText = nested.bodyText;
        if (nested.bodyHtml) bodyHtml = nested.bodyHtml;
      }
    }
  }

  return { bodyText, bodyHtml };
}

async function extractEmailHeaders(headers) {
  const result = {
    subject: '',
    from: '',
    fromName: '',
    to: '',
    cc: '',
    bcc: '',
    date: new Date(),
  };

  for (const header of headers || []) {
    const name = header.name?.toLowerCase();
    const value = header.value || '';

    switch (name) {
      case 'subject':
        result.subject = value;
        break;
      case 'from':
        result.from = value;
        const fromMatch = value.match(/^(.+?)\s*<(.+?)>$|^(.+?)$/);
        if (fromMatch) {
          result.fromName = fromMatch[1]?.trim() || fromMatch[3]?.trim() || '';
          result.from = fromMatch[2]?.trim() || fromMatch[3]?.trim() || value;
        }
        break;
      case 'to':
        result.to = value;
        break;
      case 'cc':
        result.cc = value;
        break;
      case 'bcc':
        result.bcc = value;
        break;
      case 'date':
        result.date = new Date(value);
        break;
    }
  }

  return result;
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

    const accessToken = await getValidAccessToken(userId);
    oauth2Client.setCredentials({ access_token: accessToken });
    const gmail = google.gmail({ version: 'v1', auth: oauth2Client });

    const MAX_EMAILS = 500;
    let nextPageToken = null;
    let totalSynced = 0;
    let hasMore = true;

    while (hasMore && totalSynced < MAX_EMAILS) {
      const remaining = MAX_EMAILS - totalSynced;
      const batchSize = Math.min(remaining, 500);
      
      const params = {
        maxResults: batchSize,
        q: '',
      };

      if (nextPageToken) {
        params.pageToken = nextPageToken;
      }

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
      console.log(`Fetching ${emailsToProcess.length} emails (${totalSynced + 1}-${totalSynced + emailsToProcess.length} of ${MAX_EMAILS})...`);

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
            updated_at: new Date().toISOString(),
          };

          await supabase
            .from('emails')
            .upsert(emailRecord, {
              onConflict: 'id'
            });

          return true;
        } catch (error) {
          console.error(`Error processing email ${message.id}:`, error.message);
          return false;
        }
      });

      const results = await Promise.all(emailPromises);
      totalSynced += results.filter(r => r).length;

      console.log(`Synced ${totalSynced} of ${MAX_EMAILS} emails...`);

      if (totalSynced >= MAX_EMAILS) {
        hasMore = false;
        console.log(`Reached limit of ${MAX_EMAILS} emails. Stopping sync.`);
      }

      if (totalSynced % 100 === 0 || totalSynced >= MAX_EMAILS) {
        await supabase
          .from('email_sync_status')
          .update({
            total_emails_synced: totalSynced,
            updated_at: new Date().toISOString(),
          })
          .eq('user_id', userId);
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

app.post('/api/emails/sync', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const { data: syncStatus } = await supabase
      .from('email_sync_status')
      .select('sync_in_progress')
      .eq('user_id', userId)
      .single();

    if (syncStatus && syncStatus.sync_in_progress) {
      return res.json({ 
        message: 'Sync already in progress',
        inProgress: true 
      });
    }

    syncEmailsInBackground(userId).catch(err => {
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
});

app.get('/api/emails/sync/status', verifyToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('email_sync_status')
      .select('*')
      .eq('user_id', req.user.id)
      .single();

    if (error && error.code !== 'PGRST116') {
      return res.status(500).json({ error: 'Database error' });
    }

    res.json({
      hasSynced: !!data?.last_sync_at,
      inProgress: data?.sync_in_progress || false,
      lastSyncAt: data?.last_sync_at,
      totalEmails: data?.total_emails_synced || 0,
      lastError: data?.last_sync_error,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/emails', verifyToken, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 500;
    const offset = parseInt(req.query.offset) || 0;

    console.log(`Fetching emails for user ${req.user.id}, limit: ${limit}, offset: ${offset}`);

    const { data: emails, error, count } = await supabase
      .from('emails')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id)
      .order('date', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('Database error:', error);
      return res.status(500).json({ error: 'Failed to fetch emails: ' + error.message });
    }

    console.log(`Found ${emails?.length || 0} emails in database (total: ${count || 0})`);

    if (!emails || emails.length === 0) {
      return res.json({
        emails: [],
        total: 0,
      });
    }

    const formattedEmails = emails.map(email => {
      if (!email.gmail_message_id) {
        console.warn('Email missing gmail_message_id:', email.id);
      }
      return {
        gmail_message_id: email.gmail_message_id,
        subject: email.subject || '(No Subject)',
        from_email: email.from_email || '',
        snippet: email.snippet || '',
        date: email.date,
        is_read: email.is_read || false,
      };
    });

    res.json({
      emails: formattedEmails,
      total: count || formattedEmails.length,
    });
  } catch (error) {
    console.error('Get emails error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/emails/:emailId', verifyToken, async (req, res) => {
  try {
    const { emailId } = req.params;

    const { data: email, error } = await supabase
      .from('emails')
      .select('*')
      .eq('user_id', req.user.id)
      .eq('gmail_message_id', emailId)
      .single();

    if (error || !email) {
      return res.status(404).json({ error: 'Email not found' });
    }

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
    });
  } catch (error) {
    console.error('Get email error:', error);
    res.status(500).json({ error: error.message });
  }
});

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

app.listen(PORT, '0.0.0.0', () => {
  const localIP = getLocalIP();
  console.log(`Server running on port ${PORT}`);
  console.log(`Accessible at: http://localhost:${PORT}`);
  console.log(`Accessible at: http://${localIP}:${PORT}`);
  console.log(`\nFor Android Emulator, use: http://10.0.2.2:${PORT}`);
  console.log(`For physical device, use: http://${localIP}:${PORT}`);
  console.log(`\nHealth check: http://${localIP}:${PORT}/health`);
});

