import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../ranking/presentation/pages/leaderboard_page.dart';
import '../../../store/presentation/pages/store_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _PlayTab(),
      const LeaderboardPage(),
      const StorePage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0B0B1A),
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports),
              activeIcon: Icon(Icons.sports_esports),
              label: 'Play',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              activeIcon: Icon(Icons.leaderboard),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.store),
              activeIcon: const Icon(Icons.store),
              label: 'Store',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayTab extends ConsumerWidget {
  const _PlayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess The Object'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => context.push('/friends'),
            tooltip: 'Friends',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await ref.read(authActionsProvider).signOut();
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: const Icon(Icons.help_outline,
                    size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Guess The Object',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Challenge a friend!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/host'),
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  label: const Text('Host a Game',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/join-room'),
                  icon: const Icon(Icons.login, size: 28),
                  label: const Text('Join a Game',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              if (player != null) ...[
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: player.photoUrl != null
                          ? NetworkImage(player.photoUrl!)
                          : null,
                      child: player.photoUrl == null
                          ? Text(player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${player.name} \u2022 ${player.tier} \u2022 🧠 ${player.brainPoints}',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
