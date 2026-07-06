enum ReportStatus { pending, reviewed, dismissed }

class Report {
  final String id;
  final String reporterId;
  final String reportedPlayerId;
  final String matchId;
  final String categoryId;
  final String reason;
  final String description;
  final Map<String, dynamic>? matchSnapshot;
  final ReportStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedPlayerId,
    required this.matchId,
    required this.categoryId,
    required this.reason,
    required this.description,
    this.matchSnapshot,
    this.status = ReportStatus.pending,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
  });
}
