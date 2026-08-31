/**
 * Password validation for RPS Arena.
 *
 * Rules (T79):
 *   - minimum 8 characters
 *   - maximum 64 characters
 *
 * @param {string} password
 * @returns {{ valid: boolean, error?: string }}
 */
function validatePassword(password) {
  if (typeof password !== 'string') {
    return { valid: false, error: 'Password must be a string.' };
  }

  if (password.length < 8) {
    return { valid: false, error: 'Password must be at least 8 characters.' };
  }

  if (password.length > 64) {
    return { valid: false, error: 'Password must be at most 64 characters.' };
  }

  return { valid: true };
}

module.exports = { validatePassword };
