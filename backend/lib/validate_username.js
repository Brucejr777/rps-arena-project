/**
 * Username validation for RPS Arena.
 *
 * Rules (T78):
 *   - minimum 3 characters
 *   - maximum 16 characters
 *   - allowed: letters (a-z, A-Z), digits (0-9), underscores (_)
 *   - spaces disallowed
 *   - uniqueness enforced at database level (UNIQUE constraint)
 *
 * @param {string} username
 * @returns {{ valid: boolean, error?: string }}
 */
function validateUsername(username) {
  if (typeof username !== 'string') {
    return { valid: false, error: 'Username must be a string.' };
  }

  if (username.length < 3) {
    return { valid: false, error: 'Username must be at least 3 characters.' };
  }

  if (username.length > 16) {
    return { valid: false, error: 'Username must be at most 16 characters.' };
  }

  if (!/^[a-zA-Z0-9_]+$/.test(username)) {
    return {
      valid: false,
      error: 'Username may only contain letters, numbers, and underscores.',
    };
  }

  return { valid: true };
}

module.exports = { validateUsername };
