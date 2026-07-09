import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/game_rtdb_datasource.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/repositories/game_repository.dart';

final gameRTDBDataSourceProvider = Provider<GameRTDBDataSource>((ref) {
  return GameRTDBDataSource(ref.watch(firebaseDatabaseProvider));
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepositoryImpl(
    ref.watch(gameRTDBDataSourceProvider),
    ref.watch(firestoreDataSourceProvider),
  );
});

final gameStreamProvider = StreamProvider.family<GameState, String>((ref, gameId) {
  return ref.watch(gameRepositoryProvider).watchGame(gameId);
});

final gameActionsProvider = Provider<GameActions>((ref) {
  return GameActions(ref.watch(gameRepositoryProvider));
});

class GameActions {
  final GameRepository _repo;
  GameActions(this._repo);

  Future<String> startGame({
    required String roomCode,
    required String categoryId,
    required String player1Id,
    required String player2Id,
    required String p1ObjectId,
    required String p2ObjectId,
  }) async {
    try {
      return await _repo.startGame(
        roomCode: roomCode,
        categoryId: categoryId,
        player1Id: player1Id,
        player2Id: player2Id,
        p1ObjectId: p1ObjectId,
        p2ObjectId: p2ObjectId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<void> submitTurn(String gameId, String playerId, String question) async {
    try {
      await _repo.submitTurn(gameId, playerId, question);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<void> submitAnswer(String gameId, String turnKey, String answer) async {
    try {
      await _repo.submitAnswer(gameId, turnKey, answer);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<void> makeGuess(String gameId, String playerId, String guessedObject) async {
    try {
      await _repo.makeGuess(gameId, playerId, guessedObject);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<void> confirmGuess(String gameId, bool isCorrect) async {
    try {
      await _repo.confirmGuess(gameId, isCorrect);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
