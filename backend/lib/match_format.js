/**
 * Match format validation utilities (backend).
 *
 * Validates custom match configuration values.
 */

/**
 * Validate a custom wins-required value.
 * @param {number|null} value
 * @returns {null|string} null if valid, error string if invalid
 */
function validateCustomWins(value) {
  if (value === null || value === undefined) return 'INVALID VALUE';
  if (typeof value !== 'number' || !Number.isInteger(value)) return 'INVALID VALUE';
  if (value < 2 || value > 99) return 'INVALID VALUE';
  return null;
}

/**
 * Standard match format configurations.
 */
const STANDARD_FORMATS = {
  bestOf3: { winsRequired: 2, label: 'Best of 3' },
  bestOf5: { winsRequired: 3, label: 'Best of 5' },
  bestOf7: { winsRequired: 4, label: 'Best of 7' },
  bestOf9: { winsRequired: 5, label: 'Best of 9' },
  unlimited: { winsRequired: 0, label: 'Unlimited' },
};

module.exports = { validateCustomWins, STANDARD_FORMATS };
