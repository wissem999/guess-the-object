class Turn {
  final String playerId;
  final String? question;
  final String? answer;
  final int timestamp;

  const Turn({
    required this.playerId,
    this.question,
    this.answer,
    required this.timestamp,
  });

  bool get hasQuestion => question != null;
  bool get isComplete => question != null && answer != null;
}
