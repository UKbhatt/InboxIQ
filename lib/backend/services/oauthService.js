const supabase = require('../config/database');
const { oauth2Client, SCOPES } = require('../config/oauth');
const { encrypt, decrypt } = require('../utils/encryption');

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

function generateAuthUrl(userId, redirectUri) {
  return oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
    state: userId,
    prompt: 'consent',
    redirect_uri: redirectUri,
  });
}

async function exchangeCodeForTokens(code) {
  const { tokens } = await oauth2Client.getToken(code);
  return tokens;
}

async function saveTokens(userId, tokens) {
  const encryptedRefreshToken = encrypt(tokens.refresh_token);
  const encryptedAccessToken = tokens.access_token ? encrypt(tokens.access_token) : null;

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
    throw new Error('Failed to save tokens: ' + error.message);
  }
}

async function isConnected(userId) {
  const { data, error } = await supabase
    .from('oauth_tokens')
    .select('user_id')
    .eq('user_id', userId)
    .single();

  if (error && error.code !== 'PGRST116') {
    throw new Error('Database error');
  }

  return !!data;
}

module.exports = {
  getValidAccessToken,
  generateAuthUrl,
  exchangeCodeForTokens,
  saveTokens,
  isConnected,
  oauth2Client,
};

