import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dummyFriends = [
      {'name': 'Alice', 'rating': 1450, 'tier': 'Gold', 'wins': 45, 'losses': 20},
      {'name': 'Bob', 'rating': 1320, 'tier': 'Silver', 'wins': 32, 'losses': 28},
      {'name': 'Charlie', 'rating': 1180, 'tier': 'Silver', 'wins': 25, 'losses': 35},
    ];

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
          ...dummyFriends.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final f = entry.value;
            return Card(
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
                title: Text(f['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('W: ${f['wins']}  L: ${f['losses']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${f['rating']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      f['tier'] as String,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
