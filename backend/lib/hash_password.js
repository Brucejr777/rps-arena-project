/**
 * Password hashing for RPS Arena (T79).
 *
 * Uses bcrypt so plaintext passwords are never stored.
 */

const bcrypt = require('bcrypt');

const SALT_ROUNDS = 10;

/**
 * Hashes a plaintext password with bcrypt.
 * @param {string} plaintext
 * @returns {Promise<string>} bcrypt hash
 */
async function hashPassword(plaintext) {
  return bcrypt.hash(plaintext, SALT_ROUNDS);
}

/**
 * Verifies a plaintext password against a bcrypt hash.
 * @param {string} plaintext
 * @param {string} hash
 * @returns {Promise<boolean>}
 */
async function verifyPassword(plaintext, hash) {
  return bcrypt.compare(plaintext, hash);
}

module.exports = { hashPassword, verifyPassword };
