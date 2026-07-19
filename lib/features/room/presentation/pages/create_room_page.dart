import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../lobby/presentation/providers/lobby_providers.dart';
import '../providers/room_providers.dart';

class CreateRoomPage extends ConsumerWidget {
  const CreateRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pick a Category')),
      body: Center(
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load categories')),
          data: (categories) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            children: [
              const SizedBox(height: 24),
              Text(
                'Choose your category',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your opponent will get a different object\nfrom the same category',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryCard(
                      name: cat.name,
                      description: cat.description,
                      emoji: cat.name.isNotEmpty ? cat.name[0].toUpperCase() : '?',
                      onTap: () async {
                        if (player == null) return;
                        try {
                          final code = await ref
                              .read(roomActionsProvider)
                              .createRoom(player.id, cat.id);
                          if (context.mounted) {
                            context.pushReplacement('/waiting-room/$code');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to create room: $e'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  )),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final String description;
  final String emoji;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.description,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            gradient: LinearGradient(
              colors: [
                AppTheme.darkSurface.withValues(alpha: 0.9),
                AppTheme.darkBackground.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      )),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
