# Guess The Object — Project Context

## Game Overview

Real-time multiplayer mobile game (Flutter + Firebase). Two players get secret objects from same category. Take turns asking questions. First to guess opponent's object wins.

## Tech Stack

- **Frontend:** Flutter + Dart
- **State:** Riverpod (`@riverpod` code-gen)
- **Auth:** Firebase Auth (Google + Email/Password)
- **Persistent DB:** Cloud Firestore
- **Real-time:** Firebase Realtime Database
- **Routing:** GoRouter (with auth guards)
- **Sound:** audioplayers
- **Haptics:** vibration

## Architecture

**Clean Architecture** — feature-first folder structure:

```
lib/
├── core/          # Constants, errors, theme, router
├── features/      # auth, lobby, room, game, report, ranking, profile
│   └── each: data/ domain/ presentation/
└── shared/widgets/
```

**Domain layer:** pure Dart, zero Flutter/Firebase imports.
**Data layer:** Firebase SDK confined here (Firestore + RTDB).
**Presentation layer:** Riverpod providers → ConsumerWidgets.

## Firebase Strategy

| Concern | Store |
|---|---|
| Player profiles | Firestore |
| Categories + Objects | Firestore |
| Match history | Firestore |
| Friend requests | Firestore |
| Seasons / Rankings | Firestore |
| Reports | Firestore |
| Active rooms | RTDB |
| Live game turns | RTDB |
| Matchmaking queue | RTDB |

## Game Rules

- 2 players, same category, different secret objects
- Free-text questions + free-text answers (yes/no quick buttons optional)
- Turns alternate: Ask → Answer → Switch
- Player can "Make a Guess" during their turn
- Opponent confirms: correct → guesser wins, wrong → guesser loses
- Single round per match
- ELO rating (start 1000), tiers (Bronze→Legend), weekly seasons
- Friends-only leaderboard
- Report system for unfair play

## Current State

- Full architecture documented in `/plan/` (13 files)
- NOT yet implemented — waiting for user approval to build

## Plan Files (in order of importance)

| File | Content |
|---|---|
| `plan/README.md` | Game overview, rules, tech stack |
| `plan/architecture.md` | Clean Architecture layers, data flow |
| `plan/data-model.md` | All Firestore collections + RTDB paths |
| `plan/class-diagram.md` | All entities, repos, datasources, providers, screens, widgets |
| `plan/use-case-diagram.md` | 38 use cases across 7 features |
| `plan/folder-structure.md` | Full ~115 file tree |
| `plan/build-plan.md` | 13 phases, ~50h estimate |
| `plan/game-flow.md` | State machine, turn sequence, split history |
| `plan/ranking-system.md` | ELO formula, tiers, seasons, friends |
| `plan/report-system.md` | Report flow, admin review, split history UI |
| `plan/riverpod-providers.md` | Every provider, dependency graph |
| `plan/firebase-security-rules.md` | Firestore + RTDB rules |
| `plan/audio-haptics.md` | Sound service, triggers, asset list |

## Build Order (Phases)

1. Firebase setup + Flutter init
2. Core layer (constants, errors, theme, router)
3. Auth feature (Google + Email login)
4. Lobby feature (categories, objects)
5. Room feature (create, join, quick play)
6. Game feature (ask/answer/guess/result + split history)
7. Report feature (submit + admin review)
8. Ranking feature (ELO, tiers, friends, seasons)
9. Profile feature (stats, history)
10. Shared widgets
11. Audio + Haptics
12. Firebase security rules
13. Tests

## Key Design Decisions

- RTDB for live game turns (sub-10ms latency), Firestore for everything else
- ELO calculated server-side via Cloud Function (production) or client (MVP)
- Match data copied from RTDB → Firestore on game end (snapshot for reports)
- Split turn history: "My Questions" vs "Their Questions" in game UI
- Room codes: 6-char alphanumeric
- Guess + Confirm pattern prevents false wins

## Workflow Rules (from AGENTS.md)

- Think before coding. Never rush.
- Split into small milestones. One feature at a time.
- Never modify unrelated files.
- Always explain WHY.
- Every function = single responsibility.
- Step 6: Wait for approval before coding.
