class GameStateDto {
  final String roomCode;
  final String categoryId;
  final String player1Id;
  final String player2Id;
  final String p1ObjectId;
  final String p2ObjectId;
  final String currentTurn;
  final String phase;
  final Map<String, dynamic> turns;
  final Map<String, dynamic>? guess;
  final String? winnerId;
  final int createdAt;
  final int lastActivity;

  const GameStateDto({
    required this.roomCode,
    required this.categoryId,
    required this.player1Id,
    required this.player2Id,
    required this.p1ObjectId,
    required this.p2ObjectId,
    required this.currentTurn,
    this.phase = 'playing',
    this.turns = const {},
    this.guess,
    this.winnerId,
    required this.createdAt,
    required this.lastActivity,
  });

  factory GameStateDto.fromJson(Map<String, dynamic> json) {
    return GameStateDto(
      roomCode: json['roomCode'] as String,
      categoryId: json['categoryId'] as String,
      player1Id: json['player1Id'] as String,
      player2Id: json['player2Id'] as String,
      p1ObjectId: json['p1ObjectId'] as String,
      p2ObjectId: json['p2ObjectId'] as String,
      currentTurn: json['currentTurn'] as String,
      phase: json['phase'] as String? ?? 'playing',
      turns: Map<String, dynamic>.from(json['turns'] as Map? ?? {}),
      guess: json['guess'] as Map<String, dynamic>?,
      winnerId: json['winnerId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      lastActivity: (json['lastActivity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'categoryId': categoryId,
        'player1Id': player1Id,
        'player2Id': player2Id,
        'p1ObjectId': p1ObjectId,
        'p2ObjectId': p2ObjectId,
        'currentTurn': currentTurn,
        'phase': phase,
        'turns': turns,
        if (guess != null) 'guess': guess,
        if (winnerId != null) 'winnerId': winnerId,
        'createdAt': createdAt,
        'lastActivity': lastActivity,
      };
}
