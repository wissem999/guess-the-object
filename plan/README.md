# Guess The Object

Multiplayer real-time mobile game built with Flutter + Firebase.

## Concept

Two players. Each gets a secret object from the same category. Take turns asking questions about the opponent's object. First to correctly guess the opponent's object wins.

## Game Rules

- 2 players per match
- Both players pick from same category pool (Animals, Food, Technology, Sports...)
- Each player gets a **different** secret object from that category
- Turns alternate: Player A asks → Player B answers → Player B asks → Player A answers
- Questions are free-text; answers are free-text with optional yes/no quick buttons
- Player can "guess" opponent's object at any time during their turn
- Opponent confirms if guess is **correct** or **wrong**
- Correct guess = guesser wins. Wrong guess = guesser loses.
- Single round per match
- Winner can rematch or return to lobby

## Tech Stack

| Layer | Choice |
|---|---|
| Frontend | Flutter + Dart |
| State Management | Riverpod (`@riverpod` code-gen) |
| Authentication | Firebase Auth (Google + Email/Password) |
| Persistent Storage | Cloud Firestore |
| Real-time Sync | Firebase Realtime Database |
| Routing | GoRouter |
| Sound | audioplayers package |
| Haptics | vibration package |

## Architecture

Clean Architecture with feature-first folder structure:

```
lib/
├── core/         # Constants, errors, theme, router
├── features/     # auth, lobby, room, game, profile
│   └── each has: data/ domain/ presentation/
└── shared/       # Reusable widgets
```
