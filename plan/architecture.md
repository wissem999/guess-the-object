# Architecture

## Clean Architecture Layers

```
                ┌─────────────────────────────┐
                │     PRESENTATION LAYER       │
                │  (Screens, Widgets, Providers)│
                │       Flutter + Riverpod      │
                └─────────────┬───────────────┘
                              │  depends on
                ┌─────────────▼───────────────┐
                │       DOMAIN LAYER           │
                │  (Entities, Repositories,    │
                │   Use Cases — pure Dart)     │
                └─────────────┬───────────────┘
                              │  implements
                ┌─────────────▼───────────────┐
                │        DATA LAYER            │
                │  (Firebase Auth, Firestore,  │
                │   RTDB datasources + DTOs)   │
                └─────────────────────────────┘
```

## Dependency Rule

**Arrow points inward.** Presentation depends on domain abstractions, not data implementations. Riverpod providers bridge layers via dependency injection.

- Domain layer: zero Flutter imports, zero Firebase imports
- Data layer: Firebase SDK confined here
- Presentation layer: UI reacts to state, never touches Firebase directly

## Dual Firebase Strategy

| Concern | Store |
|---|---|
| Player profiles | Firestore |
| Game categories + objects | Firestore |
| Match history | Firestore |
| Active room state (who's waiting) | RTDB |
| Live game turns + answers | RTDB |
| Matchmaking queue | RTDB |
| Presence / online status | RTDB (`onDisconnect`) |

**Why RTDB for live game:** Sub-10ms latency, no query overhead. Firestore for everything that needs querying (history, leaderboard, categories).

## Data Flow

```
User Action → Widget → Riverpod Provider → Repository Interface
       → Repository Impl → Data Source → Firebase → RTDB/Firestore
       → Stream update → Provider rebuilds → Widget rebuilds
```

## Riverpod Provider Types

| Provider | Type | Watches |
|---|---|---|
| `authStateProvider` | `StreamProvider<Player?>` | `FirebaseAuth.authStateChanges()` |
| `categoriesProvider` | `FutureProvider<List<Category>>` | Firestore query |
| `objectsByCategoryProvider` | `FutureProvider.family` | Firestore query |
| `roomStreamProvider` | `StreamProvider.family<Room>` | RTDB `/rooms/$code` |
| `gameStreamProvider` | `StreamProvider.family<GameState>` | RTDB `/activeGames/$id` |
| `turnSubmissionProvider` | `NotifierProvider` | Local + Firestore optimistic |
| `audioTriggerProvider` | Provider | Game state changes → play sound |
