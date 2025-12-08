const oauthService = require('../services/oauthService');
const emailService = require('../services/emailService');
const supabase = require('../config/database');

async function generateAuthUrl(req, res) {
  try {
    const userId = req.user.id;
    const redirectUri = process.env.GOOGLE_REDIRECT_URI?.trim();
    
    if (!redirectUri) {
      return res.status(500).json({ error: 'Redirect URI not configured' });
    }
    
    const authUrl = oauthService.generateAuthUrl(userId, redirectUri);
    
    console.log('OAuth URL generated successfully for user:', userId);
    res.json({ authUrl });
  } catch (error) {
    console.error('Error generating OAuth URL:', error);
    res.status(500).json({ error: 'Failed to generate OAuth URL: ' + error.message });
  }
}

async function handleCallback(req, res) {
  try {
    const { code, state, error: oauthError } = req.query;
    
    if (oauthError) {
      console.error('OAuth error from Google:', oauthError);
      return res.status(400).send(`OAuth error: ${oauthError}. Check Google Cloud Console redirect URI configuration.`);
    }
    
    if (!code) {
      return res.status(400).send('Authorization code is required');
    }

    const tokens = await oauthService.exchangeCodeForTokens(code);
    
    if (!tokens.refresh_token) {
      return res.status(400).send('Refresh token not provided');
    }

    const userId = state;
    if (!userId) {
      return res.status(400).send('User ID is required');
    }

    await oauthService.saveTokens(userId, tokens);

    const { data: syncStatus } = await supabase
      .from('email_sync_status')
      .select('last_sync_at')
      .eq('user_id', userId)
      .single();

    const isFirstTime = !syncStatus || !syncStatus.last_sync_at;

    if (isFirstTime) {
      console.log('First time user - starting email sync in background...');
      emailService.syncEmailsInBackground(userId).catch(err => {
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
}

async function verifyCode(req, res) {
  try {
    const { code } = req.body;
    if (!code) {
      return res.status(400).json({ error: 'Code is required' });
    }

    const tokens = await oauthService.exchangeCodeForTokens(code);
    
    if (!tokens.refresh_token) {
      return res.status(400).json({ error: 'Refresh token not provided' });
    }

    await oauthService.saveTokens(req.user.id, tokens);

    res.json({ success: true });
  } catch (error) {
    console.error('OAuth verify error:', error);
    res.status(500).json({ error: error.message });
  }
}

async function getConnectionStatus(req, res) {
  try {
    const connected = await oauthService.isConnected(req.user.id);
    res.json({ connected });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

module.exports = {
  generateAuthUrl,
  handleCallback,
  verifyCode,
  getConnectionStatus,
};

