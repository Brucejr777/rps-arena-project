/**
 * JWT authentication middleware (T87+).
 *
 * Extracts the Bearer token from the Authorization header,
 * verifies it, and attaches `req.player` with { playerId, username }.
 */

const { verifyAccessToken } = require('./tokens');

function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required.' });
  }

  const token = header.slice(7);
  try {
    const payload = verifyAccessToken(token);
    req.player = { playerId: payload.playerId, username: payload.username };
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

module.exports = { requireAuth };
