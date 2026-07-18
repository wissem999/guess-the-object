import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final ds = ref.watch(firestoreDataSourceProvider);
  return ds.searchUsers(query, userId);
});

final friendRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  final ds = ref.watch(firestoreDataSourceProvider);
  return ds.watchFriendRequests(userId);
});

final friendsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final ds = ref.watch(firestoreDataSourceProvider);
  final friendIds = await ds.getFriendIds(userId);
  if (friendIds.isEmpty) return [];
  return ds.getPlayersByIds(friendIds);
});

final friendsLeaderboardProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final friends = await ref.watch(friendsListProvider.future);
  final sorted = List<Map<String, dynamic>>.from(friends);
  sorted.sort((a, b) {
    final ra = (a['rating'] as num?)?.toInt() ?? 0;
    final rb = (b['rating'] as num?)?.toInt() ?? 0;
    return rb.compareTo(ra);
  });
  return sorted;
});
