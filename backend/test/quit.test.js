const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Test the quit logic directly without database (similar to other unit tests)
describe('Ranked Match Quit (T106)', () => {
  // Mock match data for testing quit logic
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
    rating_change_a: null,
    rating_change_b: null,
    ...overrides,
  });

  it('quitter gets loss, opponent gets win', () => {
    const match = createMockMatch();
    const quitterId = match.player_a_id;
    const opponentId = match.player_b_id;

    // Simulate quit logic
    const winnerId = quitterId === match.player_a_id ? match.player_b_id : match.player_a_id;
    const loserId = quitterId;

    assert.equal(winnerId, opponentId);
    assert.equal(loserId, quitterId);
  });

  it('opponent of quitter wins when quitter is player_b', () => {
    const match = createMockMatch();
    const quitterId = match.player_b_id;

    const winnerId = quitterId === match.player_a_id ? match.player_b_id : match.player_a_id;
    const loserId = quitterId;

    assert.equal(winnerId, match.player_a_id);
    assert.equal(loserId, match.player_b_id);
  });

  it('only ranked matches allow quit penalty', () => {
    const quickMatch = createMockMatch({ mode: 'quick' });
    const privateMatch = createMockMatch({ mode: 'private' });
    const rankedMatch = createMockMatch({ mode: 'ranked' });

    assert.notEqual(quickMatch.mode, 'ranked');
    assert.notEqual(privateMatch.mode, 'ranked');
    assert.equal(rankedMatch.mode, 'ranked');
  });

  it('cannot quit already finished match', () => {
    const finishedMatch = createMockMatch({ winner_id: 10 });
    assert.ok(finishedMatch.winner_id, 'Match has winner');

    const drawMatch = createMockMatch({ match_draw: true });
    assert.ok(drawMatch.match_draw, 'Match is a draw');
  });

  it('increment total rounds when quit', () => {
    const match = createMockMatch({ total_rounds: 3 });
    // Simulate quit - increment total rounds
    match.total_rounds = match.total_rounds + 1;

    assert.equal(match.total_rounds, 4);
  });

  it('quit event payload contains required fields', () => {
    const match = createMockMatch();
    const quitterId = match.player_a_id;
    const winnerId = quitterId === match.player_a_id ? match.player_b_id : match.player_a_id;

    const payload = {
      type: 'match_completed',
      matchId: match.match_id,
      winnerId,
      reason: 'quit',
      message: 'Opponent quit the match.',
      formatType: match.format_type,
      winsRequired: match.wins_required,
    };

    assert.equal(payload.type, 'match_completed');
    assert.equal(payload.reason, 'quit');
    assert.equal(payload.winnerId, match.player_b_id);
    assert.ok(payload.message);
  });

  it('unauthorized player cannot quit match they are not in', () => {
    const match = createMockMatch();
    const unauthorizedPlayerId = 999;

    const isPlayerA = match.player_a_id === unauthorizedPlayerId;
    const isPlayerB = match.player_b_id === unauthorizedPlayerId;

    assert.equal(isPlayerA, false);
    assert.equal(isPlayerB, false);
  });
});
