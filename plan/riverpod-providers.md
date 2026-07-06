# Riverpod Providers

## Provider Architecture

Every provider follows the pattern: `Data Source → Repository → Provider → Widget`

---

## Auth Providers

```dart
// ── Auth State Stream ────────────────────────────────────
// Watches FirebaseAuth.authStateChanges()
// Returns null if not logged in, Player object if logged in
@riverpod
Stream<Player?> authState(AuthStateRef ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.currentUser;
}

// ── Auth Actions ─────────────────────────────────────────
@riverpod
class AuthActions extends _$AuthActions {
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(authRepositoryProvider);
      return repo.signInWithGoogle();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(authRepositoryProvider);
      return repo.signInWithEmail(email, password);
    });
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
  }
}

// ── Repository DI ────────────────────────────────────────
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    authDataSource: FirebaseAuthDataSource(),
    firestoreDataSource: FirestoreDataSource(),
  );
}
```

---

## Lobby Providers

```dart
// ── Categories ───────────────────────────────────────────
@riverpod
Future<List<Category>> categories(CategoriesRef ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories();
}

// ── Objects by Category ─────────────────────────────────
@riverpod
Future<List<GameObject>> objectsByCategory(
  ObjectsByCategoryRef ref,
  String categoryId,
) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getObjectsByCategory(categoryId);
}

@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  return CategoryRepositoryImpl(
    dataSource: FirestoreDataSource(),
  );
}
```

---

## Room Providers

```dart
// ── Room Stream ──────────────────────────────────────────
// Watches RTDB /rooms/$roomCode for real-time updates
@riverpod
Stream<Room> roomStream(RoomStreamRef ref, String roomCode) {
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchRoom(roomCode);
}

// ── Create Room ──────────────────────────────────────────
@riverpod
class CreateRoom extends _$CreateRoom {
  Future<String> create(String hostId, String categoryId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      final repo = ref.read(roomRepositoryProvider);
      return repo.createRoom(hostId, categoryId);
    });
    state = result;
    return result.requireValue.code;
  }
}

// ── Join Room ────────────────────────────────────────────
@riverpod
class JoinRoom extends _$JoinRoom {
  Future<Room> join(String code, String guestId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(roomRepositoryProvider);
      return repo.joinRoom(code, guestId);
    });
    return state.requireValue;
  }
}

// ── Quick Match ──────────────────────────────────────────
@riverpod
class QuickMatch extends _$QuickMatch {
  Future<Room> find(String playerId, String categoryId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(roomRepositoryProvider);
      return repo.findQuickMatch(playerId, categoryId);
    });
    return state.requireValue;
  }
}

// ── Ready Status ─────────────────────────────────────────
@riverpod
class ReadyStatus extends _$ReadyStatus {
  Future<void> setReady(String roomCode, String playerId, bool ready) async {
    final repo = ref.read(roomRepositoryProvider);
    await repo.setPlayerReady(roomCode, playerId, ready);
  }
}

// ── Matchmaking Queue ────────────────────────────────────
@riverpod
Stream<Map<String, dynamic>> matchmakingQueue(
  MatchmakingQueueRef ref,
  String categoryId,
) {
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchQueue(categoryId);
}

@riverpod
RoomRepository roomRepository(RoomRepositoryRef ref) {
  return RoomRepositoryImpl(
    rtdbDataSource: RTDBDataSource(),
    firestoreDataSource: FirestoreDataSource(),
  );
}
```

---

## Game Providers

```dart
// ── Game State Stream ────────────────────────────────────
// Watches RTDB /activeGames/$gameId
// This is the CORE provider that drives the entire game UI
@riverpod
Stream<GameState> gameStream(GameStreamRef ref, String gameId) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.watchGame(gameId);
}

// ── Start Game ───────────────────────────────────────────
@riverpod
class StartGame extends _$StartGame {
  Future<String> start(
    String roomCode,
    String p1ObjectId,
    String p2ObjectId,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(gameRepositoryProvider);
      return repo.startGame(roomCode, p1ObjectId, p2ObjectId);
    });
    return state.requireValue;
  }
}

// ── Submit Question ──────────────────────────────────────
@riverpod
class SubmitQuestion extends _$SubmitQuestion {
  Future<void> submit(String gameId, String playerId, String question) async {
    final repo = ref.read(gameRepositoryProvider);
    await repo.submitTurn(gameId, playerId, question);
  }
}

// ── Submit Answer ────────────────────────────────────────
@riverpod
class SubmitAnswer extends _$SubmitAnswer {
  Future<void> submit(
    String gameId,
    String turnKey,
    String answer,
  ) async {
    final repo = ref.read(gameRepositoryProvider);
    await repo.submitAnswer(gameId, turnKey, answer);
  }
}

// ── Make Guess ───────────────────────────────────────────
@riverpod
class MakeGuess extends _$MakeGuess {
  Future<void> guess(String gameId, String playerId, String guessedObject) async {
    final repo = ref.read(gameRepositoryProvider);
    await repo.makeGuess(gameId, playerId, guessedObject);
  }
}

// ── Confirm Guess ────────────────────────────────────────
@riverpod
class ConfirmGuess extends _$ConfirmGuess {
  Future<void> confirm(String gameId, bool isCorrect) async {
    final repo = ref.read(gameRepositoryProvider);
    await repo.confirmGuess(gameId, isCorrect);
  }
}

@riverpod
GameRepository gameRepository(GameRepositoryRef ref) {
  return GameRepositoryImpl(
    rtdbDataSource: RTDBDataSource(),
    firestoreDataSource: FirestoreDataSource(),
  );
}
```

---

## Audio / Haptic Trigger Provider

```dart
// Watches game state changes and fires sound/haptic effects
// This is a "side effect" provider that doesn't produce new state
@riverpod
Stream<GameState> gameStreamWithAudio(
  GameStreamWithAudioRef ref,
  String gameId,
) {
  final currentUserId = ref.watch(currentUserIdProvider);
  String? prevTurn;
  GamePhase? prevPhase;

  return ref.watch(gameStreamProvider(gameId)).map((state) {
    // Turn changed → play "your turn" sound if current player
    if (prevTurn != null && prevTurn != state.currentTurn
        && state.currentTurn == currentUserId) {
      AudioService().playTurnChange();
      AudioService().vibrate(HapticType.medium);
    }

    // New question received
    if (state.turns.isNotEmpty && prevTurn != state.currentTurn
        && state.currentTurn == currentUserId) {
      AudioService().playQuestionReceived();
    }

    // Game finished → win/lose sound
    if (state.phase == GamePhase.finished && prevPhase != GamePhase.finished) {
      if (state.winnerId == currentUserId) {
        AudioService().playWin();
        AudioService().vibrate(HapticType.heavy);
      } else {
        AudioService().playLose();
        AudioService().vibrate(HapticType.light);
      }
    }

    prevTurn = state.currentTurn;
    prevPhase = state.phase;
    return state;
  });
}

// Simple provider to get current user ID
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.id;
}
```

---

## Provider Dependency Graph

```
                    ┌──────────────────────┐
                    │ authStateProvider     │
                    │ (Stream<Player?>)     │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │ currentUserIdProvider  │
                    │ (String?)             │
                    └──────────────────────┘

┌──────────────────┐    ┌──────────────────┐
│ categoriesProvider│    │ roomRepository  │
│ (Future<List>)   │    │ Provider         │
└──────────────────┘    └────────┬─────────┘
                                 │
         ┌───────────────────────┼───────────────┐
         │                       │               │
  ┌──────▼──────┐    ┌───────────▼───────┐  ┌────▼───────┐
  │ roomStream  │    │ createRoom       │  │ joinRoom   │
  │ Provider    │    │ Provider         │  │ Provider   │
  └─────────────┘    └──────────────────┘  └────────────┘

┌──────────────────┐
│ gameRepository  │
│ Provider         │
└────────┬─────────┘
         │
  ┌──────▼───────────────────────────────────────┐
  │                     gameStreamProvider        │
  │              (Stream<GameState>)              │
  └──────┬───────────────────────────────────────┘
         │
  ┌──────▼───────────────────────────────────────┐
  │              gameStreamWithAudioProvider       │
  │    (Same stream + side effects)               │
  └──────┬───────────────────────────────────────┘
         │
  ┌──────┴──────────────────┐
  │     GamePage (Consumer)  │
  └─────────────────────────┘
```
