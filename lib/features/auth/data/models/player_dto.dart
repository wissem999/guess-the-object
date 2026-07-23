class PlayerDto {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int wins;
  final int losses;
  final int rating;
  final int peakRating;
  final String tier;
  final int brainPoints;
  final int seasonWins;
  final int seasonLosses;
  final DateTime createdAt;

  const PlayerDto({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.wins = 0,
    this.losses = 0,
    this.rating = 1000,
    this.peakRating = 1000,
    this.tier = 'Bronze',
    this.brainPoints = 0,
    this.seasonWins = 0,
    this.seasonLosses = 0,
    required this.createdAt,
  });

  factory PlayerDto.fromJson(Map<String, dynamic> json) {
    return PlayerDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 1000,
      peakRating: (json['peakRating'] as num?)?.toInt() ?? 1000,
      tier: json['tier'] as String? ?? 'Bronze',
      brainPoints: (json['brainPoints'] as num?)?.toInt() ?? 0,
      seasonWins: (json['seasonWins'] as num?)?.toInt() ?? 0,
      seasonLosses: (json['seasonLosses'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'wins': wins,
        'losses': losses,
        'rating': rating,
        'peakRating': peakRating,
        'tier': tier,
        'brainPoints': brainPoints,
        'seasonWins': seasonWins,
        'seasonLosses': seasonLosses,
        'createdAt': createdAt,
      };
}
