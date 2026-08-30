# AI Algorithm Sheet

## Easy AI
- ROCK: 33.33%
- PAPER: 33.33%
- SCISSORS: 33.33%
- No history, no pattern tracking, no adaptation.

## Normal AI
- Records current-match player moves.
- Selects the counter to the player's most frequent move.
- Counter probability: 50%
- Remaining two moves: 25% each

## Hard AI
- Records current-match player moves.
- Weights recent moves higher, predicts the likely next player move.
- Favors the counter to the predicted move.
- Counter probability: 60%
- Remaining two moves: 20% each

## AI Scope Rule
AI behavior is identical across Best-of-3, Best-of-5, Best-of-7, Best-of-9,
Custom, and Unlimited match formats.