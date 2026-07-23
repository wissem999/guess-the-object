import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class StorePage extends ConsumerWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final brainPoints = player?.brainPoints ?? 0;
    final tier = player?.tier ?? 'Bronze';

    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.primary.withValues(alpha: 0.15),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$brainPoints Brain Points',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current rank: $tier',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Text(
            'How to earn Brain Points',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _RewardInfo(tier: 'Silver', reward: 50),
          _RewardInfo(tier: 'Gold', reward: 100),
          _RewardInfo(tier: 'Platinum', reward: 200),
          _RewardInfo(tier: 'Diamond', reward: 400),
          _RewardInfo(tier: 'Heroic', reward: 750),
          _RewardInfo(tier: 'Grandmaster', reward: 1500),
          const SizedBox(height: 24),
          const Text(
            'Coming Soon',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _StoreItem(
            icon: Icons.block,
            title: 'Remove Ads',
            cost: 500,
            brainPoints: brainPoints,
          ),
          _StoreItem(
            icon: Icons.category,
            title: 'Unlock New Categories',
            cost: 200,
            brainPoints: brainPoints,
          ),
          _StoreItem(
            icon: Icons.smart_toy,
            title: 'Play vs AI',
            cost: 300,
            brainPoints: brainPoints,
          ),
        ],
      ),
    );
  }
}

class _RewardInfo extends StatelessWidget {
  final String tier;
  final int reward;

  const _RewardInfo({required this.tier, required this.reward});

  @override
  Widget build(BuildContext context) {
    final tierIcons = {
      'Silver': '🥈',
      'Gold': '🥇',
      'Platinum': '💎',
      'Diamond': '💠',
      'Heroic': '⭐',
      'Grandmaster': '👑',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Text(tierIcons[tier] ?? '', style: const TextStyle(fontSize: 24)),
        title: Text('Reach $tier'),
        trailing: Text(
          '+$reward 🧠',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        dense: true,
      ),
    );
  }
}

class _StoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int cost;
  final int brainPoints;

  const _StoreItem({
    required this.icon,
    required this.title,
    required this.cost,
    required this.brainPoints,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = brainPoints >= cost;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Coming Soon', style: TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: canAfford
                ? AppTheme.success.withValues(alpha: 0.15)
                : AppTheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$cost 🧠',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: canAfford ? AppTheme.success : AppTheme.error,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
