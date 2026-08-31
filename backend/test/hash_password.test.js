const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { hashPassword, verifyPassword } = require('../lib/hash_password');

describe('hashPassword', () => {
  it('returns a bcrypt hash string', async () => {
    const hash = await hashPassword('mypassword');
    assert.strictEqual(typeof hash, 'string');
    assert.ok(hash.startsWith('$2'));
  });

  it('produces different hashes for the same input (salt randomness)', async () => {
    const hash1 = await hashPassword('mypassword');
    const hash2 = await hashPassword('mypassword');
    assert.notStrictEqual(hash1, hash2);
  });
});

describe('verifyPassword', () => {
  it('returns true for a matching password', async () => {
    const hash = await hashPassword('correcthorse');
    assert.strictEqual(await verifyPassword('correcthorse', hash), true);
  });

  it('returns false for a wrong password', async () => {
    const hash = await hashPassword('correcthorse');
    assert.strictEqual(await verifyPassword('wrongpassword', hash), false);
  });

  it('returns false when comparing plaintext to a different hash', async () => {
    const hash1 = await hashPassword('password1');
    const hash2 = await hashPassword('password2');
    assert.strictEqual(await verifyPassword('password1', hash2), false);
    assert.strictEqual(await verifyPassword('password2', hash1), false);
  });
});

describe('plaintext never stored', () => {
  it('hash does not contain the original password', async () => {
    const plaintext = 'SuperSecret123!';
    const hash = await hashPassword(plaintext);
    assert.ok(!hash.includes(plaintext));
  });

  it('hash is the right length for bcrypt (60 chars)', async () => {
    const hash = await hashPassword('anypassword');
    assert.strictEqual(hash.length, 60);
  });
});
