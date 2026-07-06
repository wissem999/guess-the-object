class RoomDto {
  final String hostId;
  final String? guestId;
  final String categoryId;
  final String status;
  final String? gameId;
  final bool hostReady;
  final bool guestReady;
  final int createdAt;

  const RoomDto({
    required this.hostId,
    this.guestId,
    required this.categoryId,
    this.status = 'waiting',
    this.gameId,
    this.hostReady = false,
    this.guestReady = false,
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
        'createdAt': createdAt,
      };
}
