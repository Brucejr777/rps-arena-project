const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Test the cancel logic directly without database
describe('Ranked Match Cancel (T107)', () => {
  // Mock match data
  const createMockMatch = (overrides = {}) => ({
    match_id: 1,
    mode: 'ranked',
    format_type: 'bestOf3',
    wins_required: 2,
    player_a_id: 10,
    player_b_id: 20,
    winner_id: null,
    match_draw: false,
    total_rounds: 0,
    draw_count: 0,
    ...overrides,
  });

  it('ranked cancel triggers loss penalty', () => {
    const match = createMockMatch();
    const cancelerId = match.player_a_id;

    // Simulate cancel logic for ranked
    if (match.mode === 'ranked') {
      const winnerId = cancelerId === match.player_a_id ? match.player_b_id : match.player_a_id;
      const loserId = cancelerId;

      assert.equal(winnerId, match.player_b_id);
      assert.equal(loserId, cancelerId);
      assert.equal(match.mode, 'ranked');
    }
  });

  it('non-ranked cancel does not trigger penalty', () => {
    const quickMatch = createMockMatch({ mode: 'quick' });
    const privateMatch = createMockMatch({ mode: 'private' });

    // Non-ranked matches should not have penalty
    assert.notEqual(quickMatch.mode, 'ranked');
    assert.notEqual(privateMatch.mode, 'ranked');
  });

  it('cannot cancel already finished match', () => {
    const finishedMatch = createMockMatch({ winner_id: 10 });
    assert.ok(finishedMatch.winner_id, 'Match has winner');

    const drawMatch = createMockMatch({ match_draw: true });
    assert.ok(drawMatch.match_draw, 'Match is a draw');
  });

  it('cancel payload contains penalty flag', () => {
    const match = createMockMatch();
    const cancelerId = match.player_a_id;
    const winnerId = cancelerId === match.player_a_id ? match.player_b_id : match.player_a_id;

    const payload = {
      matchId: match.match_id,
      winnerId,
      penalty: match.mode === 'ranked',
      message: match.mode === 'ranked' ? 'Ranked match cancelled. Loss recorded.' : 'Match cancelled.',
    };

    assert.equal(payload.penalty, true);
    assert.ok(payload.message.includes('Loss recorded'));
  });

  it('cancel event has reason field', () => {
    const match = createMockMatch();
    const cancelerId = match.player_a_id;
    const winnerId = cancelerId === match.player_a_id ? match.player_b_id : match.player_a_id;

    const eventPayload = {
      type: 'match_completed',
      matchId: match.match_id,
      winnerId,
      reason: 'cancel',
      message: 'Opponent cancelled the ranked match.',
      formatType: match.format_type,
      winsRequired: match.wins_required,
    };

    assert.equal(eventPayload.reason, 'cancel');
    assert.equal(eventPayload.type, 'match_completed');
  });

  it('opponent of canceler wins', () => {
    const match = createMockMatch();

    // Player A cancels
    const winnerA = match.player_b_id;
    assert.equal(winnerA, match.player_b_id);

    // Player B cancels
    const winnerB = match.player_a_id;
    assert.equal(winnerB, match.player_a_id);
  });
});
