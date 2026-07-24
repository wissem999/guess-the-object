class AppConstants {
  AppConstants._();

  // Turn timer
  static const int turnTimeLimitSeconds = 30;
  static const int maxTimeoutsBeforeForfeit = 3;

  // Room
  static const int roomCodeLength = 6;
  static const String roomCodeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  // Matchmaking
  static const int matchmakingPollIntervalMs = 1000;

  // ELO
  static const int eloKFactor = 32;
  static const int eloStartRating = 600;
  static const int eloUpsetMultiplier = 400;

  // Reconnection
  static const int reconnectGracePeriodSeconds = 60;

  // Limits
  static const int maxQuestionLength = 200;
  static const int maxAnswerLength = 200;
  static const int maxDescriptionLength = 500;
}
