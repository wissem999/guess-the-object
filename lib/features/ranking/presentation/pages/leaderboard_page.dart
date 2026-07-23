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
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/add-friend'),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          _SeasonHeader(tier: player?.tier ?? 'Bronze', rating: player?.rating ?? 1000),
          const SizedBox(height: 16),
          if (player != null)
            _YourRankCard(
              name: player.name,
              rating: player.rating,
              tier: player.tier,
              brainPoints: player.brainPoints,
              wins: player.wins,
              losses: player.losses,
            ),
          const SizedBox(height: 16),
          leaderboardAsync.when(
            data: (friends) {
              if (friends.isEmpty) {
                return Card(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.group_add, size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No friends yet!',
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add friends to see rankings',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final all = friends.toList();
              all.sort((a, b) {
                final ra = (a['rating'] as num?)?.toInt() ?? 0;
                final rb = (b['rating'] as num?)?.toInt() ?? 0;
                return rb.compareTo(ra);
              });

              return Column(
                children: [
                  if (all.length >= 3) _TopThreePodium(players: all),
                  const SizedBox(height: 8),
                  ...all.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final f = entry.value;
                    return _RankedPlayerCard(
                      rank: rank,
                      name: f['name'] as String? ?? 'Unknown',
                      rating: f['rating'] as int? ?? 1000,
                      tier: f['tier'] as String? ?? 'Bronze',
                      wins: f['wins'] as int? ?? 0,
                      losses: f['losses'] as int? ?? 0,
                    );
                  }),
                ],
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  final String tier;
  final int rating;

  const _SeasonHeader({required this.tier, required this.rating});

  @override
  Widget build(BuildContext context) {
    final tierColor = Color(ELOCalculator.tierColors[tier] ?? 0xFFCD7F32);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withValues(alpha: 0.2),
            tierColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Current Season',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$tier',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: tierColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$rating 🧠',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _YourRankCard extends StatelessWidget {
  final String name;
  final int rating;
  final String tier;
  final int brainPoints;
  final int wins;
  final int losses;

  const _YourRankCard({
    required this.name,
    required this.rating,
    required this.tier,
    required this.brainPoints,
    required this.wins,
    required this.losses,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = Color(ELOCalculator.tierColors[tier] ?? 0xFFCD7F32);
    final tierIcon = LeaderboardPage._tierIcons[tier] ?? '🥉';
    final progress = ELOCalculator.tierProgress(rating);
    final nextThreshold = ELOCalculator.nextTierThreshold(rating);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$name (You)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 6),
                          Text(tierIcon, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                      Text(
                        '$wins W  $losses L  \u2022  🧠 $brainPoints',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$rating',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Text(
                      tier,
                      style: TextStyle(fontSize: 11, color: tierColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(tier, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const Spacer(),
                if (nextThreshold != 999999)
                  Text('$rating / $nextThreshold', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))
                else
                  Text('MAX', style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.background,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopThreePodium extends StatelessWidget {
  final List<Map<String, dynamic>> players;

  const _TopThreePodium({required this.players});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final heights = [100.0, 80.0, 70.0];
    final colors = [Colors.amber, Colors.grey, Colors.brown];

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [1, 0, 2].map((idx) {
          if (idx >= players.length) return const SizedBox(width: 90);
          final p = players[idx];
          final name = (p['name'] as String? ?? '?');
          final rating = (p['rating'] as num?)?.toInt() ?? 1000;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: idx == 0 ? 24 : 20,
                  backgroundColor: colors[idx],
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: idx == 0 ? 18 : 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$rating',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: heights[idx],
                  width: 72,
                  decoration: BoxDecoration(
                    color: colors[idx].withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border.all(color: colors[idx].withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      medals[idx],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RankedPlayerCard extends StatelessWidget {
  final int rank;
  final String name;
  final int rating;
  final String tier;
  final int wins;
  final int losses;

  const _RankedPlayerCard({
    required this.rank,
    required this.name,
    required this.rating,
    required this.tier,
    required this.wins,
    required this.losses,
  });

  @override
  Widget build(BuildContext context) {
    final tierIcon = LeaderboardPage._tierIcons[tier] ?? '🥉';
    final tierColor = Color(ELOCalculator.tierColors[tier] ?? 0xFFCD7F32);
    final progress = ELOCalculator.tierProgress(rating);
    final nextThreshold = ELOCalculator.nextTierThreshold(rating);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? [Colors.amber, Colors.grey, Colors.brown][rank - 1].withValues(alpha: 0.2)
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: rank <= 3
                        ? [Colors.amber, Colors.grey, Colors.brown][rank - 1]
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(tierIcon, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        tier,
                        style: TextStyle(fontSize: 11, color: tierColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: AppTheme.background,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rank <= 3 ? [Colors.amber, Colors.grey, Colors.brown][rank - 1] : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (nextThreshold != 999999)
                        Text(
                          ' $nextThreshold',
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$rating',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '$wins\u2009W',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
