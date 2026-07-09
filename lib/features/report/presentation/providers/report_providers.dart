import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../lobby/data/datasources/category_datasource.dart';

final reportActionsProvider = Provider<ReportActions>((ref) {
  return ReportActions(ref.watch(firestoreDataSourceProvider));
});

class ReportActions {
  final FirestoreDataSource _firestore;
  ReportActions(this._firestore);

  Future<void> submitReport({
    required String reporterId,
    required String reportedPlayerId,
    required String matchId,
    required String categoryId,
    required String reason,
    required String description,
    required String reporterName,
  }) async {
    try {
      Map<String, dynamic>? matchSnapshot;
      try {
        matchSnapshot = await _firestore.getMatchDocument(matchId);
      } catch (_) {}

      await _firestore.submitReport({
        'reporterId': reporterId,
        'reportedPlayerId': reportedPlayerId,
        'matchId': matchId,
        'categoryId': categoryId,
        'reason': reason,
        'description': description,
        'reporterName': reporterName,
        'matchSnapshot': matchSnapshot,
        'status': 'pending',
        'createdAt': DateTime.now(),
      });
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
