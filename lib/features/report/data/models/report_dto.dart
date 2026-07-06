class ReportDto {
  final String reporterId;
  final String reportedPlayerId;
  final String matchId;
  final String categoryId;
  final String reason;
  final String description;
  final Map<String, dynamic>? matchSnapshot;
  final String status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const ReportDto({
    required this.reporterId,
    required this.reportedPlayerId,
    required this.matchId,
    required this.categoryId,
    required this.reason,
    required this.description,
    this.matchSnapshot,
    this.status = 'pending',
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory ReportDto.fromJson(Map<String, dynamic> json) {
    return ReportDto(
      reporterId: json['reporterId'] as String,
      reportedPlayerId: json['reportedPlayerId'] as String,
      matchId: json['matchId'] as String,
      categoryId: json['categoryId'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String,
      matchSnapshot: json['matchSnapshot'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      adminNote: json['adminNote'] as String?,
      createdAt: (json['createdAt'] as dynamic).toDate(),
      reviewedAt: (json['reviewedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reporterId': reporterId,
        'reportedPlayerId': reportedPlayerId,
        'matchId': matchId,
        'categoryId': categoryId,
        'reason': reason,
        'description': description,
        if (matchSnapshot != null) 'matchSnapshot': matchSnapshot,
        'status': status,
        if (adminNote != null) 'adminNote': adminNote,
        'createdAt': createdAt,
        if (reviewedAt != null) 'reviewedAt': reviewedAt,
      };
}
