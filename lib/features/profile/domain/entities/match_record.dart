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

  const MatchRecord({
    required this.id,
    required this.opponentId,
    required this.opponentName,
    required this.categoryName,
    required this.didWin,
    required this.totalTurns,
    required this.oldRating,
    required this.newRating,
    required this.ratingChange,
    required this.createdAt,
  });
}
