class Player {
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

  const Player({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.wins = 0,
    this.losses = 0,
    this.rating = 600,
    this.peakRating = 600,
    this.tier = 'Bronze',
    this.brainPoints = 0,
    this.seasonWins = 0,
    this.seasonLosses = 0,
    required this.createdAt,
  });

  int get totalGames => wins + losses;
  double get winRate => totalGames > 0 ? wins / totalGames : 0;
}
