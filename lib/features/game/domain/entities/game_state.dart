import 'turn.dart';

enum GamePhase { playing, guessing, confirming, finished }

class GameState {
  final String gameId;
  final String roomCode;
  final String categoryId;
  final String player1Id;
  final String player2Id;
  final String p1ObjectId;
  final String p2ObjectId;
  final String currentTurn;
  final GamePhase phase;
  final List<Turn> turns;
  final Guess? guess;
  final String? winnerId;
  final int createdAt;
  final int lastActivity;

  const GameState({
    required this.gameId,
    required this.roomCode,
    required this.categoryId,
    required this.player1Id,
    required this.player2Id,
    required this.p1ObjectId,
    required this.p2ObjectId,
    required this.currentTurn,
    this.phase = GamePhase.playing,
    this.turns = const [],
    this.guess,
    this.winnerId,
    required this.createdAt,
    required this.lastActivity,
  });
}

class Guess {
  final String playerId;
  final String guessedObject;
  final bool? isCorrect;

  const Guess({
    required this.playerId,
    required this.guessedObject,
    this.isCorrect,
  });
}
