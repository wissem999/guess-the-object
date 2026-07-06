class DateHelpers {
  DateHelpers._();

  static String relativeTime(int millisecondsSinceEpoch) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - millisecondsSinceEpoch;

    if (diff < 60000) {
      final seconds = (diff / 1000).round();
      return '${seconds}s ago';
    } else if (diff < 3600000) {
      final minutes = (diff / 60000).round();
      return '${minutes}m ago';
    } else if (diff < 86400000) {
      final hours = (diff / 3600000).round();
      return '${hours}h ago';
    } else {
      final days = (diff / 86400000).round();
      return '${days}d ago';
    }
  }

  static int currentTimestampMs() =>
      DateTime.now().millisecondsSinceEpoch;
}
