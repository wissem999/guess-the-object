class FirebaseConstants {
  FirebaseConstants._();

  // ── Firestore Collections ─────────────────────────────────
  static const String usersCollection = 'users';
  static const String categoriesCollection = 'categories';
  static const String objectsCollection = 'objects';
  static const String matchesCollection = 'matches';
  static const String friendRequestsCollection = 'friendRequests';
  static const String friendshipsCollection = 'friendships';
  static const String seasonsCollection = 'seasons';
  static const String reportsCollection = 'reports';

  // ── RTDB Paths ────────────────────────────────────────────
  static const String roomsPath = 'rooms';
  static const String activeGamesPath = 'activeGames';
  static const String queuePath = 'queue';

  // ── Firestore Fields ──────────────────────────────────────
  static const String fieldRating = 'rating';
  static const String fieldPeakRating = 'peakRating';
  static const String fieldTier = 'tier';
  static const String fieldBrainPoints = 'brainPoints';
  static const String fieldFriendIds = 'friendIds';
  static const String fieldStatus = 'status';
}
