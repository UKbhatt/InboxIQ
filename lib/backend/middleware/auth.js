const supabase = require('../config/database');

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

module.exports = { verifyToken };

