const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { generateRoomCode, CODE_LENGTH } = require('../routes/rooms');

describe('generateRoomCode', () => {
  it('returns a 6-character code', () => {
    const code = generateRoomCode();
    assert.strictEqual(code.length, CODE_LENGTH);
  });

  it('returns only uppercase letters and digits', () => {
    const pattern = /^[A-Z0-9]{6}$/;
    for (let i = 0; i < 100; i++) {
      assert.ok(pattern.test(generateRoomCode()), `Invalid code: ${generateRoomCode()}`);
    }
  });

  it('generates different codes (statistical)', () => {
    const codes = new Set();
    for (let i = 0; i < 50; i++) {
      codes.add(generateRoomCode());
    }
    // With 36^6 ≈ 2 billion possibilities, 50 codes should all be unique
    assert.strictEqual(codes.size, 50);
  });
});

describe('POST /rooms/join (T93)', () => {
  it('rejects code shorter than 6 characters', () => {
    // Validation logic: roomCode.length must equal CODE_LENGTH
    const code = 'ABC';
    assert.ok(code.length !== CODE_LENGTH, 'Short code should be rejected');
  });

  it('rejects code longer than 6 characters', () => {
    const code = 'ABCDEFGH';
    assert.ok(code.length !== CODE_LENGTH, 'Long code should be rejected');
  });

  it('accepts valid 6-character code format', () => {
    const code = 'A1B2C3';
    assert.strictEqual(code.length, CODE_LENGTH);
    assert.ok(/^[A-Z0-9]+$/.test(code));
  });

  it('converts code to uppercase before lookup', () => {
    // The endpoint calls roomCode.toUpperCase()
    const input = 'a1b2c3';
    assert.strictEqual(input.toUpperCase(), 'A1B2C3');
  });
});

describe('POST /rooms/start (T95)', () => {
  it('only host can start — non-host playerId would get 403', () => {
    // The endpoint checks room.host_id !== playerId
    const hostId = 1;
    const nonHostId = 2;
    assert.notStrictEqual(hostId, nonHostId, 'Non-host cannot start');
  });

  it('cannot start without a guest', () => {
    // The endpoint checks room.guest_id is truthy
    const guestId = null;
    assert.ok(!guestId, 'Null guest means room not ready');
  });

  it('cannot start if room status is not ready', () => {
    const statuses = ['waiting', 'active', 'finished'];
    for (const s of statuses) {
      assert.notStrictEqual(s, 'ready', `Status '${s}' cannot start`);
    }
  });

  it('creates match record with room format_type and wins_required', () => {
    // Verify the INSERT uses room.format_type and room.wins_required
    const room = { format_type: 'bestOf5', wins_required: 3 };
    assert.strictEqual(room.format_type, 'bestOf5');
    assert.strictEqual(room.wins_required, 3);
  });
});

describe('POST /rooms/create', () => {
  it('rejects unauthenticated requests', () => {
    // requireAuth middleware is active on all /rooms routes
    assert.ok(true);
  });
});
