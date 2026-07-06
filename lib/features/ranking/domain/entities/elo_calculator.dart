class ELOCalculator {
  ELOCalculator._();

  static double expectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + _pow10((ratingB - ratingA) / 400.0));
  }

  static int calculateNewRating(int currentRating, double expectedScore, int actualScore) {
    return currentRating + (32.0 * (actualScore - expectedScore)).round();
  }

  static String calculateTier(int rating) {
    if (rating >= 2300) return 'Legend';
    if (rating >= 2000) return 'Diamond';
    if (rating >= 1700) return 'Platinum';
    if (rating >= 1400) return 'Gold';
    if (rating >= 1000) return 'Silver';
    return 'Bronze';
  }

  static int getRatingChange(int winnerRating, int loserRating) {
    final expected = expectedScore(winnerRating, loserRating);
    return (32.0 * (1.0 - expected)).round().clamp(1, 50);
  }

  static double _pow10(double x) {
    // 10^x using e^(x * ln(10))
    return _exp(x * 2.302585092994046);
  }

  static double _exp(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}
