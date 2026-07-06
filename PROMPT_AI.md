# Guess The Object — Complete Project Specification for AI Developer

## Project Overview

**Guess The Object** is a **real-time multiplayer mobile/web game** built with **Flutter + Firebase**. Two players receive secret objects from the same category. They take turns asking each other free-text questions to narrow down the object. The first player to correctly guess the opponent's object wins. The game features ELO ranking, friends leaderboard, report system for unfair play, and split turn history.

**Platforms:** Android, iOS, Web (Chrome)
**Current State:** 53 Dart source files, 0 errors, 0 warnings on `flutter analyze`. Auth (Google + Email) works on web. Lobby, Profile, CreateRoom, JoinRoom, WaitingRoom, Game, Result, Report, Leaderboard, Friends, AddFriend pages all have skeleton UI. The remaining features need real-time multiplayer logic (RTDB), Firestore data wiring, and game state machine implementation.

---

## 1. Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter + Dart (`sdk: ^3.11.5`) |
| **State Management** | Riverpod (`flutter_riverpod: ^2.6.1`) — plain Providers + StreamProvider (NO code-gen) |
| **Auth** | Firebase Auth (`firebase_auth: ^6.5.4`) — Google + Email/Password |
| **Persistent DB** | Cloud Firestore (`cloud_firestore: ^6.6.0`) |
| **Real-time DB** | Firebase Realtime Database (`firebase_database: ^12.4.4`) |
| **Routing** | GoRouter (`go_router: ^17.3.0`) |
| **Google Sign-In** | `google_sign_in: ^7.2.0` (mobile only; web uses Firebase `signInWithPopup`) |
| **Config** | `flutter_dotenv: ^6.0.1` — `.env` file (gitignored) |
| **Sound/Haptics** | `audioplayers: ^6.7.1`, `vibration: ^3.2.0` |
| **Other** | `equatable: ^2.1.0`, `uuid: ^4.5.3`, `intl` (transitive) |

---

## 2. Architecture

**Clean Architecture — feature-first folder structure:**

```
lib/
├── core/          # Constants, errors, theme, router, utils
├── features/      # auth, lobby, room, game, report, ranking, profile
│   └── each: data/ domain/ presentation/
└── main.dart + app.dart
```

**Rules:**
- **Domain layer** (entities + repository interfaces): pure Dart, zero Flutter/Firebase imports
- **Data layer** (datasources, DTOs, repository implementations): Firebase SDK confined here
- **Presentation layer** (pages + providers): Riverpod ConsumerWidgets + providers

---

## 3. Firebase Strategy

| Concern | Store | Path/Collection |
|---|---|---|
| **Player profiles** | Firestore | `users/{userId}` |
| **Categories + Objects** | Firestore | `categories/{id}`, `objects/{id}` |
| **Match history** | Firestore | `matches/{id}` |
| **Friend requests** | Firestore | `friendRequests/{id}` |
| **Friendships** | Firestore | `friendships/{userId}` → `{ friendIds: { friendId: true } }` |
| **Seasons / Rankings** | Firestore | `seasons/{id}` |
| **Reports** | Firestore | `reports/{id}` |
| **Active rooms** | RTDB | `/rooms/{roomCode}` |
| **Live game turns** | RTDB | `/activeGames/{gameId}` |
| **Matchmaking queue** | RTDB | `/queue/{userId}` |

### Firestore Collections Schema

**`users/{userId}`**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "photoUrl": "string?",
  "wins": "int (default 0)",
  "losses": "int (default 0)",
  "rating": "int (default 1000)",
  "peakRating": "int (default 1000)",
  "tier": "int (default 'Bronze')",
  "seasonWins": "int (default 0)",
  "seasonLosses": "int (default 0)",
  "createdAt": "Timestamp"
}
```

**`categories/{id}`** — `{ id, name, iconUrl, description, order }`
**`objects/{id}`** — `{ id, name, categoryId, hints?: string[] }`
**`matches/{id}`** — full game snapshot copied from RTDB on game end (for reports)
**`friendships/{userId}`** — `{ friendIds: { friendId: true } }`
**`friendRequests/{id}`** — `{ fromId, toId, status: 'pending'|'accepted'|'rejected', createdAt }`
**`seasons/{id}`** — `{ seasonNumber, startDate, endDate, participants: { userId: { wins, losses, rating } } }`
**`reports/{id}`** — `{ reporterId, reportedId, matchId, reason, description, status: 'pending'|'reviewed', createdAt }`

### RTDB Paths

**`/rooms/{roomCode}`** (6-char alphanumeric, e.g. `ABC123`)
```json
{
  "code": "ABC123",
  "categoryId": "animals",
  "hostId": "userId1",
  "guestId": "userId2?",
  "status": "waiting|ready|playing|finished",
  "hostObjectId": "objectId?",
  "guestObjectId": "objectId?",
  "createdAt": 1234567890
}
```

**`/activeGames/{gameId}`**
```json
{
  "roomCode": "ABC123",
  "player1Id": "userId1",
  "player2Id": "userId2",
  "player1ObjectId": "objectId",
  "player2ObjectId": "objectId",
  "currentTurn": "userId1",
  "status": "playing|finished",
  "history": [
    { "askerId": "userId1", "question": "Is it alive?", "answer": "Yes", "timestamp": 123 }
  ],
  "winnerId": "userId?",
  "createdAt": 1234567890
}
```

**`/queue/{userId}`** — `{ categoryId, joinedAt, status: 'waiting'|'matched' }`

---

## 4. Game Rules & Flow

### Core Loop
1. Two players, same category, different secret objects
2. Players take TURNS: **Ask** → **Answer** → **Switch**
3. On your turn: type a free-text question OR click "Make a Guess"
4. Opponent: reads the question → types a free-text answer (or taps Yes/No/IDK quick buttons)
5. After answering, turn switches back
6. "Make a Guess": Player types what they think the opponent's object is
7. Opponent confirms: **Correct** → guesser wins || **Wrong** → guesser loses
8. **Single round per match** — no rematch

### Turn Sequence (State Machine)
```
IDLE → PLAYER1_ASK → PLAYER2_ANSWER → PLAYER2_ASK → PLAYER1_ANSWER → loop
```
- On GUESS attempt (instead of ask): `{currentTurn}_GUESS` → `{opponent}_CONFIRM` → win/lose

### Split Turn History (UI requirement)
- **"My Questions"** section: questions I asked + answers I received
- **"Opponent's Questions"** section: questions they asked + answers I gave
- Visually: chat-bubble style with different colors per section

---

## 5. ELO Ranking System

| Tier | Rating Range |
|---|---|
| Bronze | 0–999 |
| Silver | 1000–1199 |
| Gold | 1200–1399 |
| Platinum | 1400–1599 |
| Diamond | 1600–1799 |
| Master | 1800–1999 |
| Legend | 2000+ |

- **Start rating:** 1000
- **K-factor:** 32
- **Formula:** `expected = 1 / (1 + 10^((opponentRating - playerRating) / 400))`
- **New rating:** `rating + K * (actualScore - expectedScore)` (win=1, loss=0)
- **Peak rating:** tracked separately, never decreases
- **Seasons:** weekly reset (season data stored per-user in `seasons/{seasonId}/participants/{userId}`)
- **Leaderboard:** friends-only (compare ratings within friendship graph)
- **ELO calculation:** client-side for MVP, Cloud Function for production

---

## 6. Routes (GoRouter)

| Path | Page | Auth Guard |
|---|---|---|
| `/login` | LoginPage | Redirect to `/lobby` if logged in |
| `/lobby` | LobbyPage | Redirect to `/login` if not logged in |
| `/create-room` | CreateRoomPage | Auth required |
| `/join-room` | JoinRoomPage | Auth required |
| `/waiting-room/:code` | WaitingRoomPage | Auth required |
| `/pick-object/:code` | PickObjectPage | Auth required |
| `/game/:gameId` | GamePage | Auth required |
| `/result/:gameId` | ResultPage | Auth required |
| `/profile` | ProfilePage | Auth required |
| `/leaderboard` | LeaderboardPage | Auth required |
| `/friends` | FriendsPage | Auth required |
| `/add-friend` | AddFriendPage | Auth required |
| `/report/:matchId` | ReportPage | Auth required |

**Redirect logic:** `ref.read(authStateProvider).valueOrNull` — if null → `/login`, if not null and on `/login` → `/lobby`.

---

## 7. Existing Source Files (Complete)

### Entry Point — `lib/main.dart`
```dart
// Loads .env → Firebase.initializeApp with web options → GoogleSignIn.init (mobile only) → runApp(ProviderScope(child: GuessTheObjectApp()))
```

### App Widget — `lib/app.dart`
```dart
// ConsumerStatefulWidget. Watches authStateProvider, tracks _wasLoggedIn flag.
// On transition logged-in → logged-out: calls goLogin() via addPostFrameCallback.
// Returns MaterialApp.router(routerConfig: router, theme: AppTheme.light, darkTheme: AppTheme.dark)
```

### Router — `lib/core/router/app_router.dart`
```dart
// _rootNavigatorKey, appRouterProvider (Provider<GoRouter>), goLogin() helper.
// GoRouter with redirect: reads authStateProvider.valueOrNull, redirects to /login if null.
// 13 routes (see routes table above). ref.onDispose(router.dispose).
```

### Theme — `lib/core/theme/app_theme.dart`
```dart
// AppTheme class: primary=#6C63FF, secondary=#FF6584, background=#F5F5FA, surface=#FFFFFF
// light + dark ThemeData (useMaterial3: true, colorSchemeSeed: primary)
// Custom elevatedButtonTheme, inputDecorationTheme, cardTheme.
```

### Firebase Constants — `lib/core/constants/firebase_constants.dart`
```dart
// Collection names: users, categories, objects, matches, friendRequests, friendships, seasons, reports
// RTDB paths: rooms, activeGames, queue
// Field names: rating, peakRating, tier, friendIds, status
```

### App Constants — `lib/core/constants/app_constants.dart`
```dart
// turnTimeLimitSeconds=30, maxTimeoutsBeforeForfeit=3, roomCodeLength=6, eloKFactor=32, eloStartRating=1000
```

### Exceptions — `lib/core/errors/exceptions.dart`
```dart
// ServerException, CacheException, AuthException, NetworkException
```

### Failures — `lib/core/errors/failures.dart`
```dart
// Failure extends Equatable → ServerFailure, AuthFailure, CacheFailure, NetworkFailure, ValidationFailure
```

### Validators — `lib/core/utils/validators.dart`
```dart
// email(), password(), roomCode(), displayName(), question() — return String? error message
```

### Date Helpers — `lib/core/utils/date_helpers.dart`
```dart
// relativeTime(millis) → "5m ago", "2h ago", "3d ago"
```

### Auth Feature (`lib/features/auth/`)

**Entities:**
- `Player` — id, name, email, photoUrl?, wins, losses, rating, peakRating, tier, seasonWins, seasonLosses, createdAt, totalGames getter, winRate getter

**Repository interface:** `AuthRepository`
```dart
abstract class AuthRepository {
  Stream<Player?> get currentUser;
  Future<Player> signInWithGoogle();
  Future<Player> signInWithEmail(String email, String password);
  Future<Player> registerWithEmail(String email, String password, String name);
  Future<void> signOut();
  Future<void> createProfile(Player player);
}
```

**Data source:** `FirebaseAuthDataSource`
- `authStateChanges()` → stream of `User?`
- `signInWithGoogle()` — web: `FirebaseAuth.signInWithPopup(GoogleAuthProvider)`, mobile: `GoogleSignIn.instance.authenticate()` → exchange idToken via `GoogleAuthProvider.credential`
- `signInWithEmail` / `registerWithEmail` — standard Firebase methods
- `signOut()` — `_auth.signOut()` (web) || `GoogleSignIn.instance.signOut()` + `_auth.signOut()` (mobile)

**Repository impl:** `AuthRepositoryImpl`
- `currentUser`: `_authDataSource.authStateChanges().asyncExpand(...)` — when Firebase user is null → emit null; when exists → `_firestoreDataSource.watchPlayer(uid).map(dto → entity)`
- `signInWithGoogle/Email`: calls auth datasource → if user profile exists in Firestore (getPlayer), return it; else create new profile via `_handleSignIn()`
- `signOut()`: delegates to datasource

**DTO:**
```dart
PlayerDto — id, name, email, photoUrl?, wins, losses, rating, peakRating, tier, seasonWins, seasonLosses, createdAt
fromJson/toJson — handles Timestamp conversion, null/default fallbacks
```

**Providers (`auth_providers.dart`):**
```dart
firebaseAuthDataSourceProvider    → Provider<FirebaseAuthDataSource>
firestoreDataSourceProvider       → Provider<FirestoreDataSource>
authRepositoryProvider            → Provider<AuthRepository>
authStateProvider                 → StreamProvider<Player?> (from authRepository.currentUser)
authActionsProvider               → Provider<AuthActions>
currentUserIdProvider             → Provider<String?> (from authStateProvider.valueOrNull?.id)

class AuthActions {
  signInWithGoogle() → Future<Player>
  signInWithEmail(email, password) → Future<Player>
  registerWithEmail(email, password, name) → Future<Player>
  signOut() → Future<void>
}
```

**Login Page** — `login_page.dart` (317 lines)
- Gradient background (#6C63FF → #F5F5FA)
- White circular icon with glow shadow
- "Guess The Object" + "Can you figure it out?" text in white
- White Card with Google button (white bg, Google-blue G icon) + OR divider + Email button (primary bg)
- "Terms of Service" footer
- Email: ModalBottomSheet with icon, fields (Name for registration, Email, Password), toggle between Login/Register, form validation

### Lobby Feature (`lib/features/lobby/`)

**Entities:**
- `Category` — id, name, iconUrl, description, order
- `GameObject` — id, name, categoryId, hints?

**Data source:** `FirestoreDataSource` (210 lines — shared data source for ALL features)
- Player operations: `getPlayer()`, `watchPlayer()`, `createUserProfile()`, `updatePlayerRating()`
- Category: `getCategories()`, `getObjectsByCategory()`
- Match: `saveMatchRecord()`, `getMatchHistory()`
- Friends: `getFriendIds()`, `getPlayersByIds()`, `sendFriendRequest()`, `acceptFriendRequest()`, `rejectFriendRequest()`, `watchFriendRequests()`, `searchUsers()`
- Reports: `submitReport()`, `getMyReports()`
- Seasons: `getCurrentSeasonData()`

**Providers:** `lobby_providers.dart`
```dart
selectedCategoryProvider → StateProvider<String?> (null = no selection)
```

**Lobby Page** — `lobby_page.dart` (233 lines)
- AppBar: leaderboard icon, profile icon, logout icon (calls `authActionsProvider.signOut()` then `context.go('/login')`)
- Player info header (avatar, name, rating/tier, W/L record)
- Grid of 6 hardcoded categories (animals, food, tech, sports, vehicles, home) with Icons + descriptions
- Selected category highlighted in primary color
- Bottom bar: Create Room + Join Room buttons (disabled if no category selected)

### Room Feature (`lib/features/room/`)

**Entities:** `Room` — code, categoryId, hostId, guestId?, status, hostObjectId?, guestObjectId?, createdAt
**DTO:** `RoomDto` — toJson/fromJson matching RTDB schema
**Data source:** `RoomRtdbDataSource` — RTDB CRUD for rooms
**Repository interface:** `RoomRepository`

**Pages (skeleton):**
- `CreateRoomPage` — Shows room code, copy button, "Wait for Opponent" button
- `JoinRoomPage` — Text field for room code, join button
- `WaitingRoomPage` — Shows "Waiting for opponent..." with loading indicator

### Game Feature (`lib/features/game/`)

**Entities:**
- `GameState` — id, roomCode, player1Id, player2Id, player1ObjectId, player2ObjectId, currentTurn, status, winnerId?, createdAt
- `Turn` — askerId, question, answer?, timestamp

**DTOs:** `GameStateDto`, `TurnDto`

**Pages (skeleton):**
- `PickObjectPage` — grid of objects in selected category
- `GamePage` (270 lines) — split turn history (My Questions / Opponent's Questions), chat-bubble UI, question input, quick-answer buttons (Yes/No/IDK), "Make a Guess" button, turn indicator, opponent info header
- `ResultPage` — win/lose display, player stats, "Play Again" + "Back to Lobby"

### Other Features (skeleton pages)

**Profile:** `profile_page.dart` — avatar + name + tier, stats card (rating, wins, losses, win rate, peak rating), navigation to leaderboard/friends/match history, Sign Out button with error handling + `context.go('/login')`

**Ranking:**
- `LeaderboardPage` — friends leaderboard list
- `FriendsPage` — friend list + pending requests
- `AddFriendPage` — user search bar

**Report:** `report_page.dart` — reason picker (RadioListTile), description field, submit

---

## 8. Firebase Configuration

### `.env` file (at project root, gitignored)
```
FIREBASE_API_KEY=AIzaSyDIU8EchMuxZrSNMYZA4UN6caiG-922rpY
FIREBASE_AUTH_DOMAIN=guess-the-object-2f17e.firebaseapp.com
FIREBASE_PROJECT_ID=guess-the-object-2f17e
FIREBASE_STORAGE_BUCKET=guess-the-object-2f17e.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=267529989039
FIREBASE_APP_ID=1:267529989039:web:34840e655aaf7f25559d5a
GOOGLE_WEB_CLIENT_ID=267529989039-fvdu9lgbq760vv7fih45r947h7ug4noi.apps.googleusercontent.com
```

### Firebase Console Setup Required
- **Authentication**: Enable Google + Email/Password providers
- **Firestore**: Create indexes for `matches` (player1Id + createdAt desc) and `friendRequests` (toId + status)
- **RTDB**: Create database in same region as Firestore
- **Security Rules**: See `plan/firebase-security-rules.md` for complete rules

### Android (`android/app/google-services.json`) + iOS (`ios/Runner/GoogleService-Info.plist`)
Both config files are already placed in the project.

---

## 9. Current State — What's Built vs What's Missing

### ✅ Fully Working
- **Auth**: Google sign-in (web + mobile), Email/Password sign-in + registration, sign-out, `authState` stream with Firestore player profile reactive watch
- **Routing**: GoRouter with auth redirect + sign-out navigation (`goLogin()`)
- **Theme**: Light + Dark mode, Material 3
- **Login Page**: Polished UI with gradient, card, Google + Email buttons, bottom sheet for email form
- **Lobby Page**: Category grid, player info, create/join room buttons
- **All Pages**: Have skeleton widgets created (no crashes, no errors)
- **Constants**: Firebase paths, app config, validators, date helpers
- **All Entities**: Player, Category, GameObject, GameState, Turn, Room, Report, Friend, MatchRecord, EloCalculator
- **All Repository Interfaces**: Auth, Category, Room, Game, Report, Ranking, Profile
- **Data Sources**: FirebaseAuth, Firestore (full CRUD for all features), RTDB skeleton
- **Auth Repo Impl**: Complete with `asyncExpand` stream, `_handleSignIn` profile creation
- **Providers**: authState, authActions, currentUserId, selectedCategory

### 🔧 Need Implementation
- **Room Repo Impl**: Wire up RTDB for room create/join/wait
- **Game Repo Impl**: Wire up RTDB for turn-based game state + history
- **Ranking Repo Impl**: ELO calculation, leaderboard queries
- **Profile Repo Impl**: Match history, stats, update profile
- **Report Repo Impl**: Submit + review reports
- **Category Repo Impl**: Fetch from Firestore, cache locally
- **PickObjectPage**: Actually assign objects to players in room RTDB
- **GamePage**: Connect to RTDB `activeGames` stream, implement turn state machine, handle guess/confirm flow
- **WaitingRoomPage**: Listen to RTDB room status changes
- **CreateRoomPage**: Generate room code, push to RTDB
- **JoinRoomPage**: Validate and join room via room code
- **ResultPage**: Show winner/loser, ELO change, play again option
- **LeaderboardPage**: Fetch friends' ratings from Firestore
- **FriendsPage**: Send/accept/reject friend requests via Firestore
- **ReportPage**: Submit report to Firestore
- **Firebase Security Rules**: Write complete Firestore + RTDB rules
- **Testing**: Unit tests for domain, widget tests for pages
- **Sound/Haptics**: Trigger on key events (questions, guesses, wins, losses)

---

## 10. Build Order (Recommended)

1. **Room feature implementation** — Repo impl + RTDB wiring for create/join/wait/pick-object
2. **Game feature implementation** — RTDB activeGames stream, turn state machine, ask/answer/guess/confirm
3. **Result + ELO** — Calculate rating change, save match record to Firestore, display result
4. **Ranking feature** — Friends leaderboard, friend requests, search users
5. **Profile feature** — Match history list, stats display
6. **Report feature** — Submit report, admin review flow
7. **Firebase Security Rules** — Lock down Firestore + RTDB
8. **Refinement** — Loading states, error handling, empty states, edge cases
9. **Sound/Haptics** — Audio player integration
10. **Testing** — Unit + widget tests

---

## 11. Key Design Decisions

1. **RTDB for live game** (sub-10ms latency), Firestore for everything else (persistent queries)
2. **No code generation** — plain `Provider`/`StreamProvider` instead of `@riverpod` annotations (avoids `build_runner`)
3. **Platform-aware Google sign-in** — web uses Firebase `signInWithPopup`, mobile uses `google_sign_in` package singleton
4. **ELO client-side for MVP** — Cloud Function in production
5. **Match snapshot copied** from RTDB → Firestore on game end (for admin report review)
6. **Split turn history** in UI: "My Questions" vs "Their Questions" (not chronological)
7. **Room codes**: 6-char alphanumeric (uppercase + digits)
8. **Guess → Confirm** pattern prevents false wins
9. **Auth state for GoRouter**: `goLogin()` function navigates directly via `_rootNavigatorKey.currentContext?.go('/login')` as backup to redirect
10. **Firestore `watchPlayer()`** uses `.snapshots()` stream (reactive profile updates)

---

## 12. Architecture Diagram Files (in `plan/` directory)

These 13 markdown files contain the full architecture documentation. Give them to the AI as reference:

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

---

## 13. Instructions for the AI Developer

Your task: **Complete the implementation** of the Guess The Object Flutter app.

**Start with:**
1. Read ALL files in the `plan/` directory for full architecture context
2. Read all source files under `lib/` (especially `main.dart`, `app.dart`, `app_router.dart`, all providers, all datasources, all repository interfaces)
3. Wire up the Room feature (create, join, wait) using Firebase RTDB
4. Wire up the Game feature (ask, answer, guess, confirm, win/lose) using RTDB
5. Implement ELO calculation + Firestore match record
6. Implement Friends + Leaderboard
7. Implement Profile match history
8. Implement Report submission
9. Write Firebase security rules
10. Add loading states, error handling, and edge cases throughout
11. Add tests

**Don't break:**
- Auth flow (Google + Email sign-in/sign-up/sign-out)
- Auth redirect (GoRouter + `goLogin()`)
- Login page design (gradient + card + bottom sheet)
- Clean Architecture separation (domain/data/presentation layers)
- `flutter analyze` — must stay at 0 errors, 0 warnings

**Current project files:** The full Flutter project is ready with all dependencies installed, Firebase configured, and auth working. Run `flutter run -d chrome` to test on web.

**Good luck! Build something awesome.**
