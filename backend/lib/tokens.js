/**
 * JWT token utilities for RPS Arena (T80).
 *
 * Access tokens: short-lived, carry player identity.
 * Refresh tokens: longer-lived, used to obtain new access tokens.
 */

const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'access-dev-secret';
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'refresh-dev-secret';
const ACCESS_EXPIRY = '15m';
const REFRESH_EXPIRY = '7d';

function signAccessToken(playerId, username) {
  return jwt.sign({ playerId, username }, ACCESS_SECRET, {
    expiresIn: ACCESS_EXPIRY,
  });
}

function signRefreshToken(playerId) {
  // Include a random jti so every refresh token is unique,
  // ensuring rotation always invalidates the old one.
  return jwt.sign({ playerId, type: 'refresh', jti: crypto.randomUUID() }, REFRESH_SECRET, {
    expiresIn: REFRESH_EXPIRY,
  });
}

function verifyAccessToken(token) {
  return jwt.verify(token, ACCESS_SECRET);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, REFRESH_SECRET);
}

module.exports = {
  signAccessToken,
  signRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};
