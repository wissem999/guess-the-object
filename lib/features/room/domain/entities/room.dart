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
    required this.createdAt,
  });
}
