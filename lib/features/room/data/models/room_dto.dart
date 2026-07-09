class RoomDto {
  final String hostId;
  final String? guestId;
  final String categoryId;
  final String status;
  final String? gameId;
  final bool hostReady;
  final bool guestReady;
  final String? p1ObjectId;
  final String? p2ObjectId;
  final int createdAt;

  const RoomDto({
    required this.hostId,
    this.guestId,
    required this.categoryId,
    this.status = 'waiting',
    this.gameId,
    this.hostReady = false,
    this.guestReady = false,
    this.p1ObjectId,
    this.p2ObjectId,
    required this.createdAt,
  });

  factory RoomDto.fromJson(Map<String, dynamic> json) {
    return RoomDto(
      hostId: json['hostId'] as String,
      guestId: json['guestId'] as String?,
      categoryId: json['categoryId'] as String,
      status: json['status'] as String? ?? 'waiting',
      gameId: json['gameId'] as String?,
      hostReady: json['hostReady'] as bool? ?? false,
      guestReady: json['guestReady'] as bool? ?? false,
      p1ObjectId: json['p1ObjectId'] as String?,
      p2ObjectId: json['p2ObjectId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'hostId': hostId,
        if (guestId != null) 'guestId': guestId,
        'categoryId': categoryId,
        'status': status,
        if (gameId != null) 'gameId': gameId,
        'hostReady': hostReady,
        'guestReady': guestReady,
        if (p1ObjectId != null) 'p1ObjectId': p1ObjectId,
        if (p2ObjectId != null) 'p2ObjectId': p2ObjectId,
        'createdAt': createdAt,
      };
}
