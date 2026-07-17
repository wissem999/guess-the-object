import '../../../../core/errors/exceptions.dart';
import '../../../lobby/data/datasources/category_datasource.dart';
import '../../../ranking/domain/entities/elo_calculator.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/turn.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_rtdb_datasource.dart';
import '../models/game_state_dto.dart';
import '../models/turn_dto.dart';

class GameRepositoryImpl implements GameRepository {
  final GameRTDBDataSource _rtdb;
  final FirestoreDataSource _firestore;

  GameRepositoryImpl(this._rtdb, this._firestore);

  @override
  Future<String> startGame({
    required String roomCode,
    required String categoryId,
    required String player1Id,
    required String player2Id,
    required String p1ObjectId,
    required String p2ObjectId,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final data = {
        'roomCode': roomCode,
        'categoryId': categoryId,
        'player1Id': player1Id,
        'player2Id': player2Id,
        'p1ObjectId': p1ObjectId,
        'p2ObjectId': p2ObjectId,
        'currentTurn': player1Id,
        'phase': 'playing',
        'turns': {},
        'createdAt': now,
        'lastActivity': now,
      };
      final gameId = await _rtdb.createActiveGame(data);
      await _rtdb.updateGame(gameId, {
        'gameId': gameId,
        'currentTurn': player1Id,
      });
      return gameId;
    } catch (e) {
      throw ServerException('Failed to start game: $e');
    }
  }

  @override
  Stream<GameState> watchGame(String gameId) {
    return _rtdb.watchGame(gameId).map((data) {
      if (data == null) throw ServerException('Game not found');
      final dto = GameStateDto.fromJson(data);
      return _dtoToEntity(gameId, dto);
    });
  }

  @override
  Future<void> submitTurn(
      String gameId, String playerId, String question) async {
    try {
      final snapshot = await _rtdb.getGameSnapshot(gameId);
      if (snapshot == null) throw ServerException('Game not found');
      final dto = GameStateDto.fromJson(snapshot);

      final now = DateTime.now().millisecondsSinceEpoch;
      final turnsMap = Map<String, dynamic>.from(dto.turns);
      final turnKey = 'turn_${turnsMap.length}';
      final turnData = TurnDto(
        playerId: playerId,
        question: question,
        timestamp: now,
      ).toJson();
      turnsMap[turnKey] = turnData;

      await _rtdb.updateGame(gameId, {
        'turns': turnsMap,
        'currentTurn': _otherPlayer(dto, playerId),
        'lastActivity': now,
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to submit turn: $e');
    }
  }

  @override
  Future<void> submitAnswer(
      String gameId, String turnKey, String answer) async {
    try {
      final snapshot = await _rtdb.getGameSnapshot(gameId);
      if (snapshot == null) throw ServerException('Game not found');
      final dto = GameStateDto.fromJson(snapshot);

      final now = DateTime.now().millisecondsSinceEpoch;
      final turnsMap = Map<String, dynamic>.from(dto.turns);
      if (turnsMap.containsKey(turnKey)) {
        turnsMap[turnKey] = {
          ...Map<String, dynamic>.from(turnsMap[turnKey] as Map),
          'answer': answer,
        };
      }

      final nextTurn = _nextAfterAnswer(dto, turnKey);
      await _rtdb.updateGame(gameId, {
        'turns': turnsMap,
        'currentTurn': nextTurn,
        'lastActivity': now,
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to submit answer: $e');
    }
  }

  @override
  Future<void> makeGuess(
      String gameId, String playerId, String guessedObject) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _rtdb.setGuess(gameId, {
        'playerId': playerId,
        'guessedObject': guessedObject,
      });
      await _rtdb.updateGame(gameId, {
        'phase': 'guessing',
        'lastActivity': now,
      });
    } catch (e) {
      throw ServerException('Failed to submit guess: $e');
    }
  }

  @override
  Future<void> confirmGuess(String gameId, bool isCorrect) async {
    try {
      final snapshot = await _rtdb.getGameSnapshot(gameId);
      if (snapshot == null) throw ServerException('Game not found');

      final dto = GameStateDto.fromJson(snapshot);
      final guessData = dto.guess;
      if (guessData == null) throw ServerException('No guess found');

      final guessPlayerId = guessData['playerId'] as String;
      final winnerId = isCorrect ? guessPlayerId : _otherPlayer(dto, guessPlayerId);
      final loserId = _otherPlayer(dto, winnerId);

      final now = DateTime.now().millisecondsSinceEpoch;
      await _rtdb.updateGame(gameId, {
        'guess/isCorrect': isCorrect,
        'phase': 'finished',
        'winnerId': winnerId,
        'lastActivity': now,
      });

      await _saveMatchToFirestore(dto, winnerId, loserId);
      await _updateRatings(winnerId, loserId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to confirm guess: $e');
    }
  }

  Future<void> _saveMatchToFirestore(
      GameStateDto dto, String winnerId, String loserId) async {
    try {
      final turnsList = dto.turns.values.toList();
      final matchData = {
        'player1Id': dto.player1Id,
        'player2Id': dto.player2Id,
        'categoryId': dto.categoryId,
        'winnerId': winnerId,
        'loserId': loserId,
        'totalTurns': turnsList.length,
        'allTurns': turnsList,
        'roomCode': dto.roomCode,
        'createdAt': DateTime.now(),
        'endedAt': DateTime.now(),
      };
      await _firestore.saveMatchRecord(matchData);
    } catch (_) {}
  }

  Future<void> _updateRatings(String winnerId, String loserId) async {
    try {
      final winnerDto = await _firestore.getPlayer(winnerId);
      final loserDto = await _firestore.getPlayer(loserId);
      if (winnerDto == null || loserDto == null) return;

      final change =
          ELOCalculator.getRatingChange(winnerDto.rating, loserDto.rating);
      final newWinnerRating = winnerDto.rating + change;
      final newLoserRating = loserDto.rating - change;

      await _firestore.updatePlayerRating(
        winnerId,
        newWinnerRating,
        newWinnerRating > winnerDto.peakRating
            ? newWinnerRating
            : winnerDto.peakRating,
        ELOCalculator.calculateTier(newWinnerRating),
      );
      await _firestore.updatePlayerRating(
        loserId,
        newLoserRating,
        loserDto.peakRating,
        ELOCalculator.calculateTier(newLoserRating),
      );
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> getMatchDetail(String matchId) async {
    final doc = await _firestore.getMatchDocument(matchId);
    if (doc == null) throw ServerException('Match not found');
    return doc;
  }

  String _otherPlayer(GameStateDto dto, String playerId) {
    return dto.player1Id == playerId ? dto.player2Id : dto.player1Id;
  }

  String _nextAfterAnswer(GameStateDto dto, String turnKey) {
    final turnData = dto.turns[turnKey] as Map<String, dynamic>?;
    final playerId = turnData?['playerId'] as String? ?? dto.player1Id;
    return _otherPlayer(dto, playerId);
  }

  GameState _dtoToEntity(String gameId, GameStateDto dto) {
    final turnsList = <Turn>[];
    for (final entry in dto.turns.entries) {
      final turnDto = TurnDto.fromJson(
          Map<String, dynamic>.from(entry.value as Map));
      turnsList.add(Turn(
        playerId: turnDto.playerId,
        question: turnDto.question,
        answer: turnDto.answer,
        timestamp: turnDto.timestamp,
      ));
    }

    Guess? guess;
    if (dto.guess != null) {
      guess = Guess(
        playerId: dto.guess!['playerId'] as String,
        guessedObject: dto.guess!['guessedObject'] as String,
        isCorrect: dto.guess!['isCorrect'] as bool?,
      );
    }

    return GameState(
      gameId: gameId,
      roomCode: dto.roomCode,
      categoryId: dto.categoryId,
      player1Id: dto.player1Id,
      player2Id: dto.player2Id,
      p1ObjectId: dto.p1ObjectId,
      p2ObjectId: dto.p2ObjectId,
      currentTurn: dto.currentTurn,
      phase: _parsePhase(dto.phase),
      turns: turnsList,
      guess: guess,
      winnerId: dto.winnerId,
      createdAt: dto.createdAt,
      lastActivity: dto.lastActivity,
      status: dto.status,
      disconnectedAt: dto.disconnectedAt,
    );
  }

  GamePhase _parsePhase(String phase) {
    switch (phase) {
      case 'playing':
        return GamePhase.playing;
      case 'guessing':
        return GamePhase.guessing;
      case 'confirming':
        return GamePhase.confirming;
      case 'finished':
        return GamePhase.finished;
      default:
        return GamePhase.playing;
    }
  }
}
