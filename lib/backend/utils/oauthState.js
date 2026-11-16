const crypto = require('crypto');

const STATE_TTL_MS = 10 * 60 * 1000;

function sign(payload) {
  return crypto
    .createHmac('sha256', Buffer.from(process.env.ENCRYPTION_KEY, 'hex'))
    .update(`oauth-state:${payload}`)
    .digest('hex');
}

function createState(userId, now = Date.now()) {
  const payload = `${userId}.${now + STATE_TTL_MS}`;
  return `${payload}.${sign(payload)}`;
}

function verifyState(state, now = Date.now()) {
  if (typeof state !== 'string') return null;
  const parts = state.split('.');
  if (parts.length !== 3) return null;

  const [userId, expiresAt, signature] = parts;
  const expected = sign(`${userId}.${expiresAt}`);
  if (signature.length !== expected.length) return null;
  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) return null;
  if (Number(expiresAt) < now) return null;

  return userId;
}

module.exports = { createState, verifyState, STATE_TTL_MS };
