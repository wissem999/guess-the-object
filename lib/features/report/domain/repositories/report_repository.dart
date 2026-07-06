import '../entities/report.dart';

abstract class ReportRepository {
  Future<void> submitReport(Report report);
  Future<List<Report>> getMyReports(String userId);
  Future<Map<String, dynamic>> getMatchDetail(String matchId);
}
