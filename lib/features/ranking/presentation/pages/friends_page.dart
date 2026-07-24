import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/ranking_providers.dart';

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/add-friend'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Friend Requests',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No pending requests',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                );
              }
              return Column(
                children: requests.map((req) {
                  final fromId = req['fromId'] as String?;
                  final requestId = req['id'] as String?;
                  return _FriendRequestCard(
                    fromId: fromId,
                    requestId: requestId,
                  );
                }).toList(),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e', style: TextStyle(color: AppTheme.error)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          friendsAsync.when(
            data: (friends) {
              return Row(
                children: [
                  Text(
                    'All Friends (${friends.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (Object e, StackTrace s) => const SizedBox(),
          ),
          const SizedBox(height: 8),
          friendsAsync.when(
            data: (friends) {
              if (friends.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No friends yet. Search and add players!',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                );
              }
              return Column(
                children: friends.map((f) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          (f['name'] as String? ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      title: Text(
                        f['name'] as String? ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${f['tier'] ?? 'Bronze'}',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      trailing: Text(
                        '${f['rating'] ?? 600}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

class _FriendRequestCard extends ConsumerWidget {
  final String? fromId;
  final String? requestId;

  const _FriendRequestCard({required this.fromId, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fromId == null || requestId == null) return const SizedBox();

    final playerAsync = ref.watch(playerDtoStreamProvider(fromId!));

    return playerAsync.when(
      data: (player) {
        if (player == null) return const SizedBox();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('wants to be your friend'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: AppTheme.success),
                  onPressed: () async {
                    final userId = ref.read(currentUserIdProvider);
                    if (userId == null) return;
                    try {
                      await ref.read(firestoreDataSourceProvider).acceptFriendRequest(
                        requestId!, userId, fromId!,
                      );
                      ref.invalidate(friendsListProvider);
                      ref.invalidate(friendRequestsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Friend request accepted!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to accept: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: AppTheme.error),
                  onPressed: () async {
                    try {
                      await ref.read(firestoreDataSourceProvider).rejectFriendRequest(requestId!);
                      ref.invalidate(friendRequestsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Friend request declined'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to decline: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (Object e, StackTrace s) => const SizedBox(),
    );
  }
}
