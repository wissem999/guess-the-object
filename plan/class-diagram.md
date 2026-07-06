# Class Diagram

## Domain Layer (pure Dart)

### Entities

```dart
class Player {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int wins;
  final int losses;
  final int rating;
  final int peakRating;
  final String tier;
  final int seasonWins;
  final int seasonLosses;
  final DateTime createdAt;
}

class Category {
  final String id;
  final String name;
  final String iconUrl;
  final String description;
  final int order;
}

class GameObject {
  final String id;
  final String name;
  final String categoryId;
  final List<String>? hints;
}

class Room {
  final String code;
  final String hostId;
  final String? guestId;
  final String categoryId;
  final RoomStatus status;    // waiting | ready | playing | finished
  final String? gameId;
  final bool hostReady;
  final bool guestReady;
  final int createdAt;
}

enum RoomStatus { waiting, ready, playing, finished }

class GameState {
  final String gameId;
  final String roomCode;
  final String categoryId;
  final String player1Id;
  final String player2Id;
  final String p1ObjectId;   // hidden from P2 in UI
  final String p2ObjectId;   // hidden from P1 in UI
  final String currentTurn;
  final GamePhase phase;     // playing | guessing | confirming | finished
  final List<Turn> turns;
  final Guess? guess;
  final String? winnerId;
  final int createdAt;
  final int lastActivity;
}

enum GamePhase { playing, guessing, confirming, finished }

class Turn {
  final String playerId;
  final String? question;
  final String? answer;
  final int timestamp;
}

class Guess {
  final String playerId;
  final String guessedObject;
  final bool? isCorrect;     // null while waiting for confirmation
}

class MatchRecord {
  final String id;
  final String opponentId;
  final String opponentName;
  final String categoryName;
  final bool didWin;
  final int totalTurns;
  final int oldRating;
  final int newRating;
  final int ratingChange;
  final DateTime createdAt;
}

class Friend {
  final String userId;
  final String name;
  final String? photoUrl;
  final int rating;
  final String tier;
  final bool isOnline;
}

class FriendRequest {
  final String id;
  final String fromId;
  final String toId;
  final String status; // pending | accepted | rejected
  final DateTime createdAt;
}

class SeasonData {
  final int seasonNumber;
  final int peakRating;
  final int finalRating;
  final String peakTier;
  final int gamesPlayed;
  final int wins;
  final int losses;
}

class Report {
  final String id;
  final String reporterId;
  final String reportedPlayerId;
  final String matchId;
  final String categoryId;
  final String reason;       // intentional_wrong_answer | bad_words | cheating | other
  final String description;
  final Map<String, dynamic>? matchSnapshot;
  final ReportStatus status; // pending | reviewed | dismissed
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;
}

enum ReportStatus { pending, reviewed, dismissed }
```

### Repository Interfaces

```dart
abstract class AuthRepository {
  Future<Player> signInWithGoogle();
  Future<Player> signInWithEmail(String email, String password);
  Future<void> signOut();
  Stream<Player?> get currentUser;
  Future<void> createProfile(Player player);
}

abstract class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<List<GameObject>> getObjectsByCategory(String categoryId);
}

abstract class RoomRepository {
  Future<Room> createRoom(String hostId, String categoryId);
  Future<Room> joinRoom(String code, String guestId);
  Future<Room> findQuickMatch(String playerId, String categoryId);
  Stream<Room> watchRoom(String code);
  Future<void> setPlayerReady(String code, String playerId, bool ready);
  Future<void> cancelRoom(String code);
  Stream<Room> watchQueue(String categoryId);
}

abstract class GameRepository {
  Future<String> startGame(String roomCode, String p1ObjectId, String p2ObjectId);
  Stream<GameState> watchGame(String gameId);
  Future<void> submitTurn(String gameId, String playerId, String question);
  Future<void> submitAnswer(String gameId, String turnKey, String answer);
  Future<void> makeGuess(String gameId, String playerId, String guessedObject);
  Future<void> confirmGuess(String gameId, bool isCorrect);
  Future<void> saveMatch(MatchRecord record);
  Future<void> updateRatings(String winnerId, String loserId);
}

abstract class RankingRepository {
  Stream<List<Friend>> watchFriendsLeaderboard(String userId);
  Future<List<Friend>> getFriendsLeaderboard(String userId);
  Future<void> sendFriendRequest(String fromId, String toId);
  Future<void> acceptFriendRequest(String requestId, String userId, String friendId);
  Future<void> rejectFriendRequest(String requestId);
  Stream<List<FriendRequest>> watchFriendRequests(String userId);
  Future<void> searchUsers(String query);
  Future<SeasonData> getCurrentSeasonData(String userId);
  Future<List<Player>> getTopPlayers(int limit);
}

abstract class ReportRepository {
  Future<void> submitReport(Report report);
  Future<List<Report>> getMyReports(String userId);
  // Admin only:
  Future<List<Report>> getAllReports();
  Future<void> updateReportStatus(String reportId, ReportStatus status, String? adminNote);
  Future<MatchRecord> getMatchDetail(String matchId); // includes all turns
}

// Pure Dart ELO calculator (used by Cloud Function)
class ELOCalculator {
  static double expectedScore(int ratingA, int ratingB);
  static int calculateNewRating(int currentRating, double expectedScore, int score);
  static String calculateTier(int rating);
  static int getRatingChange(int winnerRating, int loserRating);
}
```

---

## Data Layer

### Data Sources

```dart
// Wraps FirebaseAuth.instance
class FirebaseAuthDataSource {
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithEmail(String email, String password);
  Stream<User?> authStateChanges();
  Future<void> signOut();
}

// Wraps FirebaseFirestore.instance
class FirestoreDataSource {
  Future<List<CategoryDto>> getCategories();
  Future<List<GameObjectDto>> getObjectsByCategory(String categoryId);
  Future<void> createUserProfile(PlayerDto dto);
  Future<void> saveMatchRecord(MatchRecordDto dto);
  Future<void> updatePlayerRating(String userId, int newRating, int peakRating, String tier);
  Future<PlayerDto> getPlayer(String userId);
  Future<List<PlayerDto>> getFriendsLeaderboard(List<String> friendIds);
  Future<void> sendFriendRequest(String fromId, String toId);
  Future<void> acceptFriendRequest(String requestId, String userId, String friendId);
  Future<void> rejectFriendRequest(String requestId);
  Stream<List<FriendRequestDto>> watchFriendRequests(String userId);
  Future<List<PlayerDto>> searchUsers(String query);
  Future<SeasonDataDto> getCurrentSeasonData(String userId);
}

// Wraps FirebaseDatabase.instance
class RTDBDataSource {
  Future<String> createRoom(RoomDto dto);
  Stream<RoomDto> watchRoom(String code);
  Future<void> joinRoom(String code, String guestId);
  Future<void> setReady(String code, String playerId, bool ready);
  Future<String> createActiveGame(GameStateDto dto);
  Stream<GameStateDto> watchGame(String gameId);
  Future<void> pushTurn(String gameId, TurnDto dto);
  Future<void> updateGuess(String gameId, GuessDto dto);
  Future<void> setWinner(String gameId, String playerId);
  Future<void> addToQueue(String categoryId, String playerId);
  Stream<Map<String, dynamic>> watchQueue(String categoryId);
  Future<void> removeFromQueue(String categoryId, String queueId);
}
```

### DTOs

```dart
@freezed
class PlayerDto with _$PlayerDto {
  const factory PlayerDto({ ... }) = _PlayerDto;
  factory PlayerDto.fromJson(Map<String, dynamic> json) => _$PlayerDtoFromJson(json);
}

@freezed
class RoomDto with _$RoomDto {
  const factory RoomDto({ ... }) = _RoomDto;
  factory RoomDto.fromJson(Map<String, dynamic> json) => _$RoomDtoFromJson(json);
}

@freezed
class GameStateDto with _$GameStateDto {
  const factory GameStateDto({ ... }) = _GameStateDto;
  factory GameStateDto.fromJson(Map<String, dynamic> json) => _$GameStateDtoFromJson(json);
}

// Same pattern for: CategoryDto, GameObjectDto, TurnDto, GuessDto, MatchRecordDto
// Plus new DTOs: FriendRequestDto, SeasonDataDto, ReportDto
```

### Repository Implementations

```dart
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource authDataSource;
  final FirestoreDataSource firestoreDataSource;

  // Maps DTOs → Entities and vice versa
}

class CategoryRepositoryImpl implements CategoryRepository {
  final FirestoreDataSource dataSource;
}

class RoomRepositoryImpl implements RoomRepository {
  final RTDBDataSource rtdbDataSource;
  final FirestoreDataSource firestoreDataSource;
}

class GameRepositoryImpl implements GameRepository {
  final RTDBDataSource rtdbDataSource;
  final FirestoreDataSource firestoreDataSource;

  // updateRatings calls ELOCalculator + firestoreDataSource.updatePlayerRating
}

class RankingRepositoryImpl implements RankingRepository {
  final FirestoreDataSource firestoreDataSource;
}

class ReportRepositoryImpl implements ReportRepository {
  final FirestoreDataSource firestoreDataSource;
}
```

---

## Presentation Layer

### Riverpod Providers

```dart
// Auth
@riverpod
Stream<Player?> authState(AuthStateRef ref) { ... }

// Lobby
@riverpod
Future<List<Category>> categories(CategoriesRef ref) { ... }

@riverpod
Future<List<GameObject>> objectsByCategory(ObjectsByCategoryRef ref, String categoryId) { ... }

// Room
@riverpod
Stream<Room> roomStream(RoomStreamRef ref, String roomCode) { ... }

@riverpod
Stream<Map<String, dynamic>> matchmakingQueue(MatchmakingQueueRef ref, String categoryId) { ... }

// Game
@riverpod
Stream<GameState> gameStream(GameStreamRef ref, String gameId) { ... }

@riverpod
class TurnSubmission extends _$TurnSubmission { ... }

// Ranking
@riverpod
Future<List<Friend>> friendsLeaderboard(FriendsLeaderboardRef ref) { ... }

@riverpod
Future<List<FriendRequest>> friendRequests(FriendRequestsRef ref) { ... }

@riverpod
class SendFriendRequest extends _$SendFriendRequest { ... }

@riverpod
Future<SeasonData> currentSeason(CurrentSeasonRef ref) { ... }

// Reports
@riverpod
Future<List<Report>> myReports(MyReportsRef ref) { ... }

@riverpod
class SubmitReport extends _$SubmitReport { ... }

// Audio triggers
@riverpod
GameState gameStreamWithAudio(GameStreamWithAudioRef ref, String gameId) { ... }
```

### Screens

```dart
class LoginPage extends ConsumerWidget            // Google + Email login
class LobbyPage extends ConsumerWidget            // Category pick + actions
class CreateRoomPage extends ConsumerWidget       // Shows room code to share
class JoinRoomPage extends ConsumerStatefulWidget // Enter code
class WaitingRoomPage extends ConsumerWidget      // Waiting for opponent
class PickObjectPage extends ConsumerWidget       // Select secret object
class GamePage extends ConsumerWidget             // Ask/Answer/Guess loop (split history)
class ResultPage extends ConsumerWidget           // Win/Lose + ELO change + report button
class ProfilePage extends ConsumerWidget          // Stats, history, ranking
class LeaderboardPage extends ConsumerWidget      // Friends-only leaderboard
class FriendsPage extends ConsumerWidget          // Friend list + requests
class AddFriendPage extends ConsumerStatefulWidget // Search + send request
class ReportPage extends ConsumerStatefulWidget   // Submit report form
```

### Shared Widgets

```dart
class AppButton extends StatelessWidget           // Primary/secondary buttons
class LoadingOverlay extends StatelessWidget      // Full screen loader
class CategoryCard extends StatelessWidget        // Category display card
class QuestionBubble extends StatelessWidget      // Outgoing question bubble
class AnswerBubble extends StatelessWidget        // Incoming answer bubble
class TurnTimer extends StatelessWidget           // 30s countdown
class YesNoQuickButtons extends StatelessWidget   // Yes/No toggles
class OpponentInfoCard extends StatelessWidget    // Opponent name + status
class GuessDialog extends StatelessWidget         // "Make a guess" input dialog
class TurnHistoryList extends StatelessWidget     // Scrollable Q&A history
class TierBadge extends StatelessWidget           // Tier icon + label
class RatingChangeIndicator extends StatelessWidget // +12 / -24 animated display
class FriendTile extends StatelessWidget          // Friend row in leaderboard
class ReportButton extends StatelessWidget        // "Report player" icon button
class MyQuestionCard extends StatelessWidget      // "My Q: ... → Their A: ..." card
class OpponentQuestionCard extends StatelessWidget // "Their Q: ... → My A: ..." card
```
