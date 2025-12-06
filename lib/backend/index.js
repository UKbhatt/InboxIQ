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

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID?.trim();
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET?.trim();
const GOOGLE_REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI?.trim();

const oauth2Client = new google.auth.OAuth2(
  GOOGLE_CLIENT_ID,
  GOOGLE_CLIENT_SECRET,
  GOOGLE_REDIRECT_URI
);

console.log('OAuth2 Client initialized:');
console.log('  Client ID:', GOOGLE_CLIENT_ID);
console.log('  Redirect URI:', GOOGLE_REDIRECT_URI);
console.log('  Redirect URI length:', GOOGLE_REDIRECT_URI?.length);
console.log('  Client Secret:', GOOGLE_CLIENT_SECRET ? '***' + GOOGLE_CLIENT_SECRET.slice(-4) : 'NOT SET');

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
    
    if (!GOOGLE_REDIRECT_URI) {
      return res.status(500).json({ error: 'Redirect URI not configured' });
    }
    
    const redirectUri = GOOGLE_REDIRECT_URI.trim();
    console.log('Using redirect URI:', redirectUri);
    console.log('Redirect URI length:', redirectUri.length);
    console.log('Redirect URI (no spaces):', JSON.stringify(redirectUri));
    
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
    const { error } = await supabase
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

    if (error) {
      console.error('Database error:', error);
      return res.status(500).send('Failed to save tokens: ' + error.message);
    }

    console.log('✓ Tokens saved successfully for user:', userId);
    res.send(`
      <html>
        <body>
          <h1>Gmail Connected Successfully!</h1>
          <p>You can close this window and return to the app.</p>
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

app.get('/api/emails', verifyToken, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const pageToken = req.query.pageToken;

    const accessToken = await getValidAccessToken(req.user.id);
    oauth2Client.setCredentials({ access_token: accessToken });

    const gmail = google.gmail({ version: 'v1', auth: oauth2Client });

    const params = {
      maxResults: limit,
      q: 'in:inbox',
    };

    if (pageToken) {
      params.pageToken = pageToken;
    }

    const response = await gmail.users.messages.list({
      userId: 'me',
      ...params,
    });

    const messages = response.data.messages || [];
    const nextPageToken = response.data.nextPageToken;

    const emailPromises = messages.slice(0, limit).map((message) =>
      gmail.users.messages.get({
        userId: 'me',
        id: message.id,
        format: 'metadata',
        metadataHeaders: ['From', 'Subject'],
      })
    );

    const emailDetails = await Promise.all(emailPromises);
    const emails = emailDetails.map((email) => email.data);

    res.json({
      emails,
      nextPageToken,
    });
  } catch (error) {
    console.error('Get emails error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/emails/:emailId', verifyToken, async (req, res) => {
  try {
    const { emailId } = req.params;

    const accessToken = await getValidAccessToken(req.user.id);
    oauth2Client.setCredentials({ access_token: accessToken });

    const gmail = google.gmail({ version: 'v1', auth: oauth2Client });

    const response = await gmail.users.messages.get({
      userId: 'me',
      id: emailId,
      format: 'full',
    });

    res.json(response.data);
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

