# Guess The Object — Project Guide

## What This Is

Real-time multiplayer guessing game. Flutter + Firebase. Two players get secret objects from the same category, ask questions, first to guess opponent's object wins.

**User:** Android phone only, no PC. Uses Termux + OpenCode. APK built via GitHub Actions.
**GitHub:** `wissem999/guess-the-object`
**Firebase project:** `guess-the-object-2f17e`

---

## How to Build

User has NO PC. All builds go through GitHub Actions:
- Push to `main` branch → GitHub Actions builds APK automatically
- APK stored as artifact + auto-created GitHub Release
- Workflow: `.github/workflows/build.yml`

**DO NOT try to build locally.** This environment cannot reach `storage.googleapis.com` or `pub.dev`.

To trigger a build: `git push` to `main`. The workflow handles everything.

---

## Current State (What Works)

### Fully Working
- **Auth:** Google sign-in, Email/Password sign-in + registration, sign-out
- **Lobby:** Category grid, player info, create/join room buttons
- **Room:** Create room with 6-char code, join by code, waiting room with room code copy, auto-start game when opponent joins
- **Game:** Ask/answer questions, make guesses, confirm guesses, win/lose flow, turn alternation, split turn history (My Questions)
- **Result:** Shows winner, ELO change, rating update in Firestore
- **Profile:** Stats display (rating, wins, losses, win rate, peak rating), sign out
- **Ranking:** Leaderboard page (friends), Friends page, Add friend search
- **Report:** Report submission with reason picker
- **In-App Updates:** Checks `update.json` on GitHub, shows dialog, downloads APK, triggers Android installer

### Built But Needs Testing/Polish
- Quick play / matchmaking queue
- Season system
- Sound / haptics (dependencies added, no triggers wired)

---

## Known Bugs & Issues

### Critical
- None currently (last batch of fixes resolved the major issues)

### Previously Fixed (for reference)
- **ServerException on app switch:** `onDisconnect().remove()` was deleting rooms/games. Fixed by changing to `onDisconnect().update({status: 'disconnected'})` with reconnection flow.
- **Login buttons not responding:** `_EmailAuthSheet` passed `WidgetRef` across route boundaries. Fixed by wrapping in fresh `Consumer`. Google button had no loading state. Added generic catch blocks in `AuthActions`.
- **Loading spinners during turns:** Replaced `CircularProgressIndicator` with hourglass icon + text-only waiting bars.

### Minor / cosmetic
- Leaderboard uses hardcoded/dummy data in some views
- Some pages still show skeleton UI elements
- No offline support
- No pull-to-refresh on any list

---

## Architecture

```
lib/
├── main.dart                    # Firebase init, GoogleSignIn init, run app
├── app.dart                     # ConsumerStatefulWidget, auth listener, update check
├── core/
│   ├── constants/               # app_constants.dart, firebase_constants.dart
│   ├── errors/                  # exceptions.dart, failures.dart
│   ├── router/                  # app_router.dart (GoRouter with auth guards)
│   ├── theme/                   # app_theme.dart (light + dark Material 3)
│   └── utils/                   # validators.dart, date_helpers.dart
├── features/
│   ├── auth/                    # Google + Email auth, player profiles
│   ├── lobby/                   # Categories, objects, FirestoreDataSource (shared)
│   ├── room/                    # RTDB rooms, create/join/wait
│   ├── game/                    # RTDB game state, turns, guesses
│   ├── profile/                 # Player stats, match history
│   ├── ranking/                 # ELO calculator, friends, leaderboard
│   └── report/                  # Report submission
├── services/
│   └── update_service.dart      # In-app update logic
└── widgets/
    └── update_dialog.dart       # Update dialog + download progress
```

**Each feature follows:** `data/` (datasources, DTOs, repo impl) → `domain/` (entities, repo interfaces) → `presentation/` (pages, providers)

**State management:** Riverpod (plain Provider/StreamProvider, NO code-gen for providers)
**Routing:** GoRouter with auth redirect
**Real-time:** Firebase RTDB for rooms + games, Firestore for everything else

---

## Key Files Reference

| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point. Firebase + GoogleSignIn init |
| `lib/app.dart` | Root widget. Auth listener. Update check on startup |
| `lib/core/router/app_router.dart` | All routes, auth guard, `goLogin()`/`goLobby()` helpers |
| `lib/features/auth/presentation/providers/auth_providers.dart` | All auth providers, `AuthActions` class, `currentUserIdProvider` |
| `lib/features/lobby/data/datasources/category_datasource.dart` | `FirestoreDataSource` — shared across ALL features |
| `lib/features/room/data/datasources/room_rtdb_datasource.dart` | RTDB room CRUD, `onDisconnect` handling |
| `lib/features/game/data/datasources/game_rtdb_datasource.dart` | RTDB game CRUD, `onDisconnect` handling |
| `lib/features/game/data/repositories/game_repository_impl.dart` | Game logic: turns, guesses, ELO, match save |
| `lib/services/update_service.dart` | Update check, download, install |
| `lib/widgets/update_dialog.dart` | Custom themed update dialog |

---

## Configuration

### Environment Variables (`.env`, gitignored)
```
FIREBASE_API_KEY=...
FIREBASE_AUTH_DOMAIN=...
FIREBASE_PROJECT_ID=...
FIREBASE_STORAGE_BUCKET=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_APP_ID=...
FIREBASE_DATABASE_URL=...
GOOGLE_WEB_CLIENT_ID=...
```

These are stored as GitHub Actions secrets and written to `.env` during CI build.

### Firebase Config
- `android/app/google-services.json` — Android Firebase config (package name: `com.guesstheobject.guess_the_object`)
- Firestore collections: users, categories, objects, matches, friendRequests, friendships, seasons, reports
- RTDB paths: rooms, activeGames, queue

### In-App Updates
- `update.json` at repo root — version manifest
- Served via `raw.githubusercontent.com/wissem999/guess-the-object/main/update.json`
- CI auto-updates it after each release with `[skip ci]` to prevent loops
- To release: bump `version:` in `pubspec.yaml`, push to `main`

### Android Permissions (AndroidManifest.xml)
- `REQUEST_INSTALL_PACKAGES` — for in-app APK install
- FileProvider configured for APK cache sharing

---

## How the CI/CD Pipeline Works

1. Push to `main` → workflow triggers
2. Creates `.env` from secrets
3. `flutter pub get` → `flutter build apk --release`
4. Uploads APK as artifact
5. Reads version from `pubspec.yaml`
6. If no GitHub Release exists for this version:
   - Creates Release with APK attached
   - Updates `update.json` with new version + download URL
   - Commits + pushes `update.json` with `[skip ci]`

**To release a new version:**
1. Edit `version:` in `pubspec.yaml` (e.g., `1.0.1+2`)
2. Push to `main`
3. That's it. CI handles the rest.

---

## Rules for AI Agents

1. **Read this file first** before making any changes
2. **Do NOT try to build locally** — push to `main` and let CI build
3. **Do NOT modify unrelated files** when fixing a bug
4. **One feature at a time** — don't batch unrelated changes
5. **Test mentally** — think about what breaks before editing
6. **Keep `flutter analyze` clean** — 0 errors, 0 warnings
7. **Preserve the dark theme** — all UI uses `#0B0B1A`/`#120A2E` backgrounds, `#6C4EF8` primary
8. **Never hardcode secrets** — use `.env` + `flutter_dotenv`
9. **RTDB for real-time** (rooms, games), **Firestore for persistent data** (profiles, matches)
10. **Riverpod plain providers** — no code-gen for new providers unless already using it in that file

---

## What Needs To Be Done Next

### High Priority
- [ ] Test full game flow end-to-end on real Android devices (2 phones)
- [ ] Fix any remaining bugs from real-device testing
- [ ] Leaderboard: wire to real Firestore data instead of dummy data
- [ ] Friends: fully wire send/accept/reject friend requests

### Medium Priority
- [ ] Season system: implement weekly season resets
- [ ] Quick play / matchmaking: test queue matching works
- [ ] Profile: add match history list from Firestore
- [ ] Report: wire to Firestore, add admin review

### Low Priority
- [ ] Sound effects on key events (question asked, guess made, win/lose)
- [ ] Haptic feedback on button presses
- [ ] Pull-to-refresh on lobby and leaderboard
- [ ] Offline error handling / no-internet banner
- [ ] App icon / splash screen customization
- [ ] iOS build configuration (currently Android-only)

### Technical Debt
- [ ] Add unit tests for ELO calculator
- [ ] Add widget tests for critical flows
- [ ] Consider Cloud Functions for ELO calculation (currently client-side)
- [ ] Firebase Security Rules need to be written/deployed
- [ ] `FirestoreDataSource` is a god-class — consider splitting per feature

---

## Firebase Security Rules (Not Yet Deployed)

Rules are documented in `plan/firebase-security-rules.md` but have NOT been deployed to Firebase. The RTDB and Firestore databases are currently open (default rules). **This is a security risk for production.**

---

## Git History

The repo has been actively developed. Key commits:
- Initial architecture + all feature files
- Auth fixes (Google sign-in, email auth, WidgetRef passing)
- Room/Game RTDB wiring with onDisconnect handling
- Disconnection status + reconnection timer
- Loading spinner removal
- In-app update system

**GitHub token** (for pushes): stored in git config, do not expose.
