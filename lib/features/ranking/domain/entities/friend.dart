class Friend {
  final String userId;
  final String name;
  final String? photoUrl;
  final int rating;
  final String tier;
  final bool isOnline;

  const Friend({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.rating,
    required this.tier,
    this.isOnline = false,
  });
}

class FriendRequest {
  final String id;
  final String fromId;
  final String toId;
  final String status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.status,
    required this.createdAt,
  });
}

class SeasonData {
  final int seasonNumber;
  final int peakRating;
  final int finalRating;
  final String peakTier;
  final int gamesPlayed;
  final int wins;
  final int losses;

  const SeasonData({
    required this.seasonNumber,
    required this.peakRating,
    required this.finalRating,
    required this.peakTier,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
  });
}
