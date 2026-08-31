const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { validatePassword } = require('../lib/validate_password');

describe('validatePassword', () => {
  // --- Valid passwords ---

  it('accepts an 8-character password (minimum)', () => {
    assert.deepStrictEqual(validatePassword('password'), { valid: true });
  });

  it('accepts a 64-character password (maximum)', () => {
    assert.deepStrictEqual(validatePassword('a'.repeat(64)), { valid: true });
  });

  it('accepts a typical strong password', () => {
    assert.deepStrictEqual(validatePassword('MyP@ssw0rd!'), { valid: true });
  });

  it('accepts a 32-character password', () => {
    assert.deepStrictEqual(validatePassword('a'.repeat(32)), { valid: true });
  });

  // --- Too short ---

  it('rejects empty string', () => {
    const result = validatePassword('');
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('at least 8'));
  });

  it('rejects 7 characters', () => {
    const result = validatePassword('1234567');
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('at least 8'));
  });

  it('rejects 1 character', () => {
    assert.strictEqual(validatePassword('a').valid, false);
  });

  // --- Too long ---

  it('rejects 65 characters', () => {
    const result = validatePassword('a'.repeat(65));
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('at most 64'));
  });

  it('rejects 100 characters', () => {
    assert.strictEqual(validatePassword('a'.repeat(100)).valid, false);
  });

  // --- Type validation ---

  it('rejects non-string input (number)', () => {
    const result = validatePassword(12345678);
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('string'));
  });

  it('rejects non-string input (null)', () => {
    assert.strictEqual(validatePassword(null).valid, false);
  });

  it('rejects non-string input (undefined)', () => {
    assert.strictEqual(validatePassword(undefined).valid, false);
  });
});
