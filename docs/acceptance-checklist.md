# RPS Arena Acceptance Checklist

This checklist belongs to T02. M1 owns this checklist. This checklist contains the required acceptance areas for RPS Arena version 1.0.0.

This checklist excludes Phase 6 future content. Excluded content includes additional themes, achievements, friends system, seasonal rankings, additional cosmetic content, and additional animation packs.

## Checklist Items

| # | Required Item | Acceptance Condition |
|---:|---|---|
| 1 | Best-of-3 | A Best-of-3 match ends when a player reaches 2 wins. |
| 2 | Best-of-5 | A Best-of-5 match ends when a player reaches 3 wins. |
| 3 | Best-of-7 | A Best-of-7 match ends when a player reaches 4 wins. |
| 4 | Best-of-9 | A Best-of-9 match ends when a player reaches 5 wins. |
| 5 | Custom Match | Custom Match uses a player-selected wins required value. Accepted values are integers 2 through 99. |
| 6 | Unlimited Match | Unlimited Match continues until END MATCH finalizes the match. |
| 7 | Custom minimum 2 wins | Custom Match rejects values below 2 and displays INVALID VALUE. |
| 8 | Custom maximum 99 wins | Custom Match rejects values above 99 and displays INVALID VALUE. |
| 9 | draw handling | A drawn round awards no point, replays in standard formats, increases draw count in Unlimited, and displays DRAW. |
| 10 | 10-second timer | The selection timer starts after GO!, lasts 10 seconds, warns at five seconds, auto-selects at zero, and displays AUTO after reveal. |
| 11 | Easy AI | Easy AI selects ROCK, PAPER, SCISSORS with equal probability. |
| 12 | Normal AI | Normal AI records current-match player moves, selects the counter to the most frequent player move, and uses 50% counter probability. |
| 13 | Hard AI | Hard AI records current-match player moves, weights recent moves higher, predicts the likely next player move, and uses 60% counter probability. |
| 14 | local privacy | Player 1 selection remains hidden and displays LOCKED until Player 2 submits a move. |
| 15 | Quick Match | Quick Match places players into format-specific queues, displays SEARCHING FOR OPPONENT..., displays rating, displays MATCH LENGTH, provides CANCEL, and pairs two players. |
| 16 | Private Room | Private Room uses a six-character uppercase alphanumeric code for host creation and guest join. |
| 17 | Ranked Match | Ranked Match uses fixed Best-of-3, updates rating, updates rank, updates leaderboard, updates online statistics, and records ranked match history. |
| 18 | Ranked fixed Best-of-3 | Ranked Match accepts no match format selection and uses wins required 2. |
| 19 | server authority | The server validates online moves, determines official online results, and prevents client-declared results. |
| 20 | disconnect | A disconnected online match starts a 30-second reconnect window and displays CONNECTION LOST. |
| 21 | reconnect | A successful reconnect restores latest match state and score. A failed reconnect assigns loss to the disconnected player and win to the opponent. |
| 22 | rating | New rating starts at 1000. Ranked Win adds 20. Ranked Loss subtracts 20. Draw adds 0. Rating floor is 0. |
| 23 | rank tiers | Bronze 0-999, Silver 1000-1499, Gold 1500-1999, Platinum 2000-2499, Diamond 2500-2999, and Master 3000+ update by rating threshold. |
| 24 | leaderboard | The global leaderboard sorts players by rating descending and refreshes when the leaderboard screen opens. |
| 25 | online statistics | Quick Match, Private Room, Ranked Match, and Unlimited online matches update online matches, rounds, draws, move counts, and win rate. Quick Match and Private Room do not update rating. Unlimited online matches do not update rating. |
| 26 | ranked match history | Ranked Match records history with date, opponent, mode, format, result, rating before, rating after, and rank change. Quick Match and Private Room do not record rating change. |
| 27 | themes | Normal theme and Space theme change hand designs, backgrounds, effects, animations, sounds, and music. Themes do not change match rules. |
| 28 | settings | Appearance, Audio, Gameplay, and Data settings persist after app restart. RESET SETTINGS restores Blue app color, Normal theme, master volume 100%, music volume 70%, sound effects volume 90%, animation speed FULL, victory animations ON, and vibration ON. |
| 29 | local statistics | Offline matches update local matches, rounds, draws, move counts, and win rate. Win rate equals Matches Won × 100 ÷ Matches Played. Matches Played zero displays 0.0%. |

## Checklist Status

- [ ] Best-of-3
- [ ] Best-of-5
- [ ] Best-of-7
- [ ] Best-of-9
- [ ] Custom Match
- [ ] Unlimited Match
- [ ] Custom minimum 2 wins
- [ ] Custom maximum 99 wins
- [ ] draw handling
- [ ] 10-second timer
- [ ] Easy AI
- [ ] Normal AI
- [ ] Hard AI
- [ ] local privacy
- [ ] Quick Match
- [ ] Private Room
- [ ] Ranked Match
- [ ] Ranked fixed Best-of-3
- [ ] server authority
- [ ] disconnect
- [ ] reconnect
- [ ] rating
- [ ] rank tiers
- [ ] leaderboard
- [ ] online statistics
- [ ] ranked match history
- [ ] themes
- [ ] settings
- [ ] local statistics