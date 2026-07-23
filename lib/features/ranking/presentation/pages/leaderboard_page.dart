import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/elo_calculator.dart';
import '../providers/ranking_providers.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  static const _tierIcons = {
    'Bronze': '🥉',
    'Silver': '🥈',
    'Gold': '🥇',
    'Platinum': '💎',
    'Diamond': '💠',
    'Heroic': '⭐',
    'Grandmaster': '👑',
  };

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
            _PlayerCard(
              name: player.name,
              rating: player.rating,
              tier: player.tier,
              wins: player.wins,
              losses: player.losses,
              isYou: true,
              rank: 0,
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
                  return _PlayerCard(
                    name: f['name'] as String? ?? 'Unknown',
                    rating: f['rating'] as int? ?? 1000,
                    tier: f['tier'] as String? ?? 'Bronze',
                    wins: f['wins'] as int? ?? 0,
                    losses: f['losses'] as int? ?? 0,
                    isYou: false,
                    rank: rank,
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

class _PlayerCard extends StatelessWidget {
  final String name;
  final int rating;
  final String tier;
  final int wins;
  final int losses;
  final bool isYou;
  final int rank;

  const _PlayerCard({
    required this.name,
    required this.rating,
    required this.tier,
    required this.wins,
    required this.losses,
    required this.isYou,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final tierIcon = LeaderboardPage._tierIcons[tier] ?? '🥉';
    final progress = ELOCalculator.tierProgress(rating);
    final nextThreshold = ELOCalculator.nextTierThreshold(rating);

    return Card(
      color: isYou ? AppTheme.primary.withValues(alpha: 0.15) : null,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isYou
            ? BorderSide(color: AppTheme.primary.withValues(alpha: 0.4), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: rank == 1
                    ? Colors.amber
                    : rank == 2
                        ? Colors.grey
                        : rank == 3
                            ? Colors.brown
                            : AppTheme.primary.withValues(alpha: 0.2),
                child: rank == 0
                    ? const Icon(Icons.person, color: Colors.white)
                    : Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? Colors.white : null,
                        ),
                      ),
              ),
              title: Row(
                children: [
                  Text(
                    '$name${isYou ? ' (You)' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(tierIcon, style: const TextStyle(fontSize: 16)),
                ],
              ),
              subtitle: Text('W: $wins  L: $losses', style: const TextStyle(fontSize: 12)),
              trailing: Text(
                '$rating',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(tier, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const Spacer(),
                if (nextThreshold != 999999)
                  Text(
                    '$rating / $nextThreshold',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  )
                else
                  Text(
                    'Max Rank',
                    style: TextStyle(fontSize: 11, color: AppTheme.success),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppTheme.cardBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isYou ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
