import '../entities/game_state.dart';

abstract class GameRepository {
  Future<String> startGame({
    required String roomCode,
    required String categoryId,
    required String player1Id,
    required String player2Id,
    required String p1ObjectId,
    required String p2ObjectId,
  });
  Stream<GameState> watchGame(String gameId);
  Future<void> submitTurn(String gameId, String playerId, String question);
  Future<void> submitAnswer(String gameId, String turnKey, String answer);
  Future<void> makeGuess(String gameId, String playerId, String guessedObject);
  Future<void> confirmGuess(String gameId, bool isCorrect);
  Future<Map<String, dynamic>> getMatchDetail(String matchId);
}
