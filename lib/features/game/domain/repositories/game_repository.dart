import '../entities/game_state.dart';

abstract class GameRepository {
  Future<String> startGame(String roomCode, String p1ObjectId, String p2ObjectId);
  Stream<GameState> watchGame(String gameId);
  Future<void> submitTurn(String gameId, String playerId, String question);
  Future<void> submitAnswer(String gameId, String turnKey, String answer);
  Future<void> makeGuess(String gameId, String playerId, String guessedObject);
  Future<void> confirmGuess(String gameId, bool isCorrect);
  Future<Map<String, dynamic>> getMatchDetail(String matchId);
}
