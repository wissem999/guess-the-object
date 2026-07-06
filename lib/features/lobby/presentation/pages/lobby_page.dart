import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../providers/lobby_providers.dart';

final dummyCategoriesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'id': 'animals', 'name': 'Animals', 'icon': Icons.pets, 'desc': 'From pets to wild beasts'},
    {'id': 'food', 'name': 'Food & Drinks', 'icon': Icons.restaurant, 'desc': 'Things you can eat'},
    {'id': 'tech', 'name': 'Technology', 'icon': Icons.computer, 'desc': 'Gadgets and devices'},
    {'id': 'sports', 'name': 'Sports', 'icon': Icons.sports_tennis, 'desc': 'Sports equipment'},
    {'id': 'vehicles', 'name': 'Vehicles', 'icon': Icons.directions_car, 'desc': 'Things that move'},
    {'id': 'home', 'name': 'Home Items', 'icon': Icons.home, 'desc': 'Everything at home'},
  ];
});

class LobbyPage extends ConsumerWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final categories = ref.watch(dummyCategoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess The Object'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.push('/leaderboard'),
            tooltip: 'Leaderboard',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await ref.read(authActionsProvider).signOut();
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign out failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: player?.photoUrl != null
                      ? NetworkImage(player!.photoUrl!)
                      : null,
                  child: player?.photoUrl == null
                      ? Text(player?.name.isNotEmpty == true
                          ? player!.name[0].toUpperCase()
                          : '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player?.name ?? 'Player',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Rating: ${player?.rating ?? 1000} \u2022 ${player?.tier ?? 'Bronze'}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (player != null)
                  Column(
                    children: [
                      Text(
                        '${player.wins}W',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${player.losses}L',
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Category section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Pick a Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCat == cat['id'];
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state =
                        isSelected ? null : cat['id'] as String;
                  },
                  child: Card(
                    color: isSelected ? AppTheme.primary : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 36,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        Text(
                          cat['desc'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white70
                                : AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedCat == null
                        ? null
                        : () => context.push('/create-room'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Room'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedCat == null
                        ? null
                        : () => context.push('/join-room'),
                    icon: const Icon(Icons.login),
                    label: const Text('Join Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
