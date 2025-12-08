const { google } = require('googleapis');

const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID?.trim(),
  process.env.GOOGLE_CLIENT_SECRET?.trim(),
  process.env.GOOGLE_REDIRECT_URI?.trim()
);

const SCOPES = ['https://www.googleapis.com/auth/gmail.readonly'];

console.log('OAuth2 Client initialized:');
console.log('  Client ID:', process.env.GOOGLE_CLIENT_ID?.trim());
console.log('  Redirect URI:', process.env.GOOGLE_REDIRECT_URI?.trim());
console.log('  Client Secret:', process.env.GOOGLE_CLIENT_SECRET ? '***' + process.env.GOOGLE_CLIENT_SECRET.slice(-4) : 'NOT SET');

module.exports = {
  oauth2Client,
  SCOPES,
};

