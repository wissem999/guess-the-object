enum RoomStatus { waiting, ready, playing, finished }

class Room {
  final String code;
  final String hostId;
  final String? guestId;
  final String categoryId;
  final RoomStatus status;
  final String? gameId;
  final bool hostReady;
  final bool guestReady;
  final String? p1ObjectId;
  final String? p2ObjectId;
  final int createdAt;

  const Room({
    required this.code,
    required this.hostId,
    this.guestId,
    required this.categoryId,
    this.status = RoomStatus.waiting,
    this.gameId,
    this.hostReady = false,
    this.guestReady = false,
    this.p1ObjectId,
    this.p2ObjectId,
    required this.createdAt,
  });

  bool get bothObjectsPicked => p1ObjectId != null && p2ObjectId != null;
}
