const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { validateUsername } = require('../lib/validate_username');

describe('validateUsername', () => {
  // --- Valid usernames ---

  it('accepts a 3-character username (minimum)', () => {
    assert.deepStrictEqual(validateUsername('abc'), { valid: true });
  });

  it('accepts a 16-character username (maximum)', () => {
    assert.deepStrictEqual(validateUsername('a'.repeat(16)), { valid: true });
  });

  it('accepts letters', () => {
    assert.deepStrictEqual(validateUsername('PlayerOne'), { valid: true });
  });

  it('accepts numbers', () => {
    assert.deepStrictEqual(validateUsername('123'), { valid: true });
  });

  it('accepts underscores', () => {
    assert.deepStrictEqual(validateUsername('my_name'), { valid: true });
  });

  it('accepts mixed letters, numbers, and underscores', () => {
    assert.deepStrictEqual(validateUsername('Cool_Pl4yer'), { valid: true });
  });

  it('accepts uppercase and lowercase letters', () => {
    assert.deepStrictEqual(validateUsername('AbC_123'), { valid: true });
  });

  // --- Too short ---

  it('rejects empty string', () => {
    const result = validateUsername('');
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('at least 3'));
  });

  it('rejects 1 character', () => {
    assert.strictEqual(validateUsername('a').valid, false);
  });

  it('rejects 2 characters', () => {
    assert.strictEqual(validateUsername('ab').valid, false);
  });

  // --- Too long ---

  it('rejects 17 characters', () => {
    const result = validateUsername('a'.repeat(17));
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('at most 16'));
  });

  it('rejects 100 characters', () => {
    assert.strictEqual(validateUsername('a'.repeat(100)).valid, false);
  });

  // --- Invalid characters ---

  it('rejects spaces', () => {
    const result = validateUsername('my name');
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('letters, numbers, and underscores'));
  });

  it('rejects special characters (period)', () => {
    assert.strictEqual(validateUsername('user.name').valid, false);
  });

  it('rejects special characters (hyphen)', () => {
    assert.strictEqual(validateUsername('user-name').valid, false);
  });

  it('rejects special characters (at sign)', () => {
    assert.strictEqual(validateUsername('@user').valid, false);
  });

  it('rejects special characters (space in middle)', () => {
    assert.strictEqual(validateUsername('a b').valid, false);
  });

  it('rejects Chinese characters', () => {
    assert.strictEqual(validateUsername('玩家').valid, false);
  });

  it('rejects emoji', () => {
    assert.strictEqual(validateUsername('🎮player').valid, false);
  });

  // --- Type validation ---

  it('rejects non-string input (number)', () => {
    const result = validateUsername(123);
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('string'));
  });

  it('rejects non-string input (null)', () => {
    assert.strictEqual(validateUsername(null).valid, false);
  });

  it('rejects non-string input (undefined)', () => {
    assert.strictEqual(validateUsername(undefined).valid, false);
  });
});
