# API Route Map

## Auth
- POST /auth/register
- POST /auth/login
- POST /auth/logout
- POST /auth/refresh

## Quick Match
- POST /quick-match/join
- DELETE /quick-match/cancel
- POST /quick-match/ready

## Rooms
- POST /rooms/create
- POST /rooms/join
- POST /rooms/start

## Matches
- POST /matches/{matchId}/move
- POST /matches/{matchId}/end
- GET /matches/{matchId}/state

## Leaderboard / Profile / Stats
- GET /leaderboard
- GET /profile
- GET /statistics
- GET /match-history

## WebSocket Channel
wss://api.rpsarena.staging/matches/{matchId}/events

(Replace with the real Render URL once staging is live, e.g.
wss://rps-arena-backend.onrender.com/matches/{matchId}/events)

### WebSocket Events
- opponent_connected
- opponent_found
- round_result
- match_completed
- opponent_disconnected
- reconnect_state