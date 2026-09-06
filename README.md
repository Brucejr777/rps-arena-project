# RPS Arena

Rock-Paper-Scissors competitive multiplayer game built with Flutter and Node.js.

## Features

- **Single Player** — Easy, Normal, Hard AI with adaptive difficulty
- **Local Multiplayer** — 2-player pass-and-play with hidden selection
- **Online Multiplayer** — Quick Match, Private Room, Ranked Match
- **Match Formats** — Best-of-3, Best-of-5, Best-of-7, Best-of-9, Custom (2–99 wins), Unlimited
- **Ranked System** — ELO rating, tier progression (Bronze → Master), global leaderboard
- **Themes** — Normal and Space themes with unique hand designs, sounds, and music
- **Customization** — 5 app colors, animation speed, victory animations, vibration

## Tech Stack

| Layer | Technology |
|---|---|
| Client | Flutter 3.13.2, Dart 3.13.2 |
| State | flutter_riverpod |
| Navigation | go_router |
| HTTP | dio |
| WebSocket | web_socket_channel |
| Storage | shared_preferences + flutter_secure_storage |
| Backend | Node.js, Express, PostgreSQL |
| Auth | JWT + bcrypt |

## Project Structure

```
rps_arena_project/
├── lib/
│   ├── core/           # Theme, network, services, router
│   ├── features/
│   │   ├── auth/       # Login, register, guest access
│   │   ├── match/      # Game engine, AI, resolution, screens
│   │   ├── online/     # Quick match, rooms, ranked, socket
│   │   ├── profile/    # Player profile, stats, history
│   │   ├── settings/   # Appearance, audio, gameplay, data
│   │   └── stats/      # Local statistics, achievements
│   └── main.dart
├── test/               # Flutter unit and widget tests
├── backend/
│   ├── routes/         # Express API routes
│   ├── lib/            # Rating, queue, auth, validation
│   ├── test/           # Backend test suites
│   └── server.js       # Entry point
└── docs/               # Documentation and checklists
```

## Getting Started

### Prerequisites

- Flutter 3.13.2+
- Node.js LTS
- PostgreSQL

### Flutter Client

```bash
flutter pub get
flutter run
```

### Backend

```bash
cd backend
npm install
cp .env.example .env   # Configure database and JWT secrets
npm start
```

## Testing

```bash
# Flutter tests
flutter test

# Backend tests
cd backend && npm test
```

## Documentation

- [Execution Plan](Execution_Plan.txt) — Full task breakdown (T01–T132)
- [Acceptance Checklist](docs/acceptance-checklist.md) — 29 acceptance criteria
- [Final Test Matrix](docs/final_test_matrix.md) — 41 named test cases
- [API Routes](backend/docs/api_routes.md) — REST and WebSocket endpoints
- [AI Algorithm Sheet](backend/docs/ai_algorithm_sheet.md) — AI difficulty specs
- [Toolchain Versions](docs/toolchain_versions.md) — Dependency versions
