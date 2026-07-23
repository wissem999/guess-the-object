class ELOCalculator {
  ELOCalculator._();

  static double expectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + _pow10((ratingB - ratingA) / 400.0));
  }

  static int calculateNewRating(int currentRating, double expectedScore, int actualScore) {
    return currentRating + (32.0 * (actualScore - expectedScore)).round();
  }

  static String calculateTier(int rating) {
    if (rating >= 3200) return 'Grandmaster';
    if (rating >= 2500) return 'Heroic';
    if (rating >= 2000) return 'Diamond';
    if (rating >= 1600) return 'Platinum';
    if (rating >= 1200) return 'Gold';
    if (rating >= 800) return 'Silver';
    return 'Bronze';
  }

  static int tierThreshold(String tier) {
    switch (tier) {
      case 'Bronze': return 0;
      case 'Silver': return 800;
      case 'Gold': return 1200;
      case 'Platinum': return 1600;
      case 'Diamond': return 2000;
      case 'Heroic': return 2500;
      case 'Grandmaster': return 3200;
      default: return 0;
    }
  }

  static int nextTierThreshold(int rating) {
    if (rating < 800) return 800;
    if (rating < 1200) return 1200;
    if (rating < 1600) return 1600;
    if (rating < 2000) return 2000;
    if (rating < 2500) return 2500;
    if (rating < 3200) return 3200;
    return 999999;
  }

  static double tierProgress(int rating) {
    final current = tierThreshold(calculateTier(rating));
    final next = nextTierThreshold(rating);
    if (next == 999999) return 1.0;
    return ((rating - current) / (next - current)).clamp(0.0, 1.0);
  }

  static int getRatingChange(int winnerRating, int loserRating) {
    final expected = expectedScore(winnerRating, loserRating);
    return (32.0 * (1.0 - expected)).round().clamp(1, 50);
  }

  static const _tierOrder = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Heroic', 'Grandmaster'];

  static int tierIndex(String tier) => _tierOrder.indexOf(tier).clamp(0, 6);

  static int tierUpReward(String oldTier, String newTier) {
    final oldIdx = tierIndex(oldTier);
    final newIdx = tierIndex(newTier);
    if (newIdx <= oldIdx) return 0;
    switch (newIdx) {
      case 1: return 50;
      case 2: return 100;
      case 3: return 200;
      case 4: return 400;
      case 5: return 750;
      case 6: return 1500;
      default: return 0;
    }
  }

  static const tierColors = {
    'Bronze': 0xFFCD7F32,
    'Silver': 0xFFC0C0C0,
    'Gold': 0xFFFFD700,
    'Platinum': 0xFF00CED1,
    'Diamond': 0xFFB9F2FF,
    'Heroic': 0xFFFF4444,
    'Grandmaster': 0xFFFFD700,
  };

  static double _pow10(double x) {
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
