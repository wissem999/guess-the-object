import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final matchHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value([]);
  return ref.watch(firestoreDataSourceProvider).getMatchHistory(userId);
});
