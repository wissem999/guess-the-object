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
    'Platinum': '⚡',
    'Diamond': '💎',
    'Heroic': '⭐',
    'Grandmaster': '👑',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final leaderboardAsync = ref.watch(friendsLeaderboardProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          _SeasonHeader(tier: player?.tier ?? 'Bronze', rating: player?.rating ?? 600),
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
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.group_add_rounded, size: 48, color: AppTheme.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'No friends yet!',
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add friends to see rankings',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
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
                      rating: f['rating'] as int? ?? 600,
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
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: TextStyle(color: AppTheme.error)),
            ),
          ),
          const SizedBox(height: 16),
          const _RankRequirementsCard(),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.15),
            AppTheme.cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [tierColor.withValues(alpha: 0.3), tierColor.withValues(alpha: 0.1)],
              ),
              border: Border.all(color: tierColor.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                LeaderboardPage._tierIcons[tier] ?? '🥉',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT RANK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: tierColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$rating',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: tierColor,
                ),
              ),
              Text(
                'ELO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
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
    final winRate = wins + losses > 0 ? (wins / (wins + losses) * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.08),
            AppTheme.cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(tierIcon, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$wins\u2009W  $losses\u2009L  \u2022  $winRate%\u2009W  \u2022  🧠$brainPoints',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$rating',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primary),
                    ),
                    Text(
                      tier,
                      style: TextStyle(fontSize: 11, color: tierColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  tier.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                const Spacer(),
                if (nextThreshold != 999999)
                  Text(
                    '$rating / $nextThreshold',
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  )
                else
                  Text(
                    'MAX',
                    style: TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
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
    final colors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];
    final bgColors = [Color(0x25FFD700), Color(0x25C0C0C0), Color(0x25CD7F32)];

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [1, 0, 2].map((idx) {
          if (idx >= players.length) return const SizedBox(width: 90);
          final p = players[idx];
          final name = (p['name'] as String? ?? '?');
          final rating = (p['rating'] as num?)?.toInt() ?? 600;
          final tier = (p['tier'] as String?) ?? 'Bronze';
          final tierColor = Color(ELOCalculator.tierColors[tier] ?? 0xFFCD7F32);

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: idx == 0 ? 52 : 44,
                  height: idx == 0 ? 52 : 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colors[idx], colors[idx].withValues(alpha: 0.5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors[idx].withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: idx == 0 ? 20 : 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
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
                const SizedBox(height: 2),
                Text(
                  '$rating',
                  style: TextStyle(
                    fontSize: 10,
                    color: tierColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: heights[idx],
                  width: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [bgColors[idx], bgColors[idx].withValues(alpha: 0.3)],
                    ),
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
    final rankColors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];
    final winRate = wins + losses > 0 ? (wins / (wins + losses) * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3 ? rankColors[rank - 1].withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? rankColors[rank - 1].withValues(alpha: 0.15)
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: rank <= 3 ? rankColors[rank - 1].withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: rank <= 3 ? rankColors[rank - 1] : AppTheme.textSecondary,
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
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(tierIcon, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        tier,
                        style: TextStyle(fontSize: 10, color: tierColor, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: AppTheme.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rank <= 3 ? rankColors[rank - 1] : tierColor,
                            ),
                          ),
                        ),
                      ),
                      if (nextThreshold != 999999)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '$nextThreshold',
                            style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                          ),
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
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary),
                ),
                Text(
                  '$wins\u2009W $losses\u2009L \u2022 $winRate%',
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRequirementsCard extends StatelessWidget {
  const _RankRequirementsCard();

  static const _ranks = [
    ('Bronze', '🥉', 0, 0xFFCD7F32),
    ('Silver', '🥈', 800, 0xFFC0C0C0),
    ('Gold', '🥇', 1200, 0xFFFFD700),
    ('Platinum', '⚡', 1600, 0xFF00CED1),
    ('Diamond', '💎', 2000, 0xFFB9F2FF),
    ('Heroic', '⭐', 2500, 0xFFFF4444),
    ('Grandmaster', '👑', 3200, 0xFFFFD700),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RANK REQUIREMENTS',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ..._ranks.map((r) {
            final (name, icon, elo, color) = r;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(color),
                      ),
                    ),
                  ),
                  Text(
                    elo == 0 ? 'Start' : '$elo+',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
