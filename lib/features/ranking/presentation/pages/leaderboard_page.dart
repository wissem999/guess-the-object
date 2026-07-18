import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/ranking_providers.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final leaderboardAsync = ref.watch(friendsLeaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text(
                'Friends Ranking',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('/add-friend'),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add Friend'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (player != null)
            Card(
              color: AppTheme.primary.withValues(alpha: 0.15),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                title: Text(
                  '${player.name} (You)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('W: ${player.wins}  L: ${player.losses}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${player.rating}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      player.tier,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          leaderboardAsync.when(
            data: (friends) {
              if (friends.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No friends yet. Add friends to see rankings!',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                );
              }
              return Column(
                children: friends.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final f = entry.value;
                  final wins = f['wins'] ?? 0;
                  final losses = f['losses'] ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rank == 1
                            ? Colors.amber
                            : rank == 2
                                ? Colors.grey
                                : rank == 3
                                    ? Colors.brown
                                    : AppTheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: rank <= 3 ? Colors.white : null,
                          ),
                        ),
                      ),
                      title: Text(
                        f['name'] as String? ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('W: $wins  L: $losses'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${f['rating'] ?? 1000}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${f['tier'] ?? 'Bronze'}',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: TextStyle(color: AppTheme.error)),
            ),
          ),
        ],
      ),
    );
  }
}
