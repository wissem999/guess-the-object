import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ResultPage extends ConsumerWidget {
  final String gameId;
  const ResultPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final didWin = gameId.hashCode.isEven;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: didWin
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.error.withValues(alpha: 0.1),
                ),
                child: Icon(
                  didWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 64,
                  color: didWin ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                didWin ? 'You Won!' : 'You Lost!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: didWin ? AppTheme.success : AppTheme.error,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  didWin ? '+12 Rating' : '-24 Rating',
                  style: TextStyle(
                    color: didWin ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Rematch
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Rematch'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/lobby'),
                icon: const Icon(Icons.home),
                label: const Text('Back to Lobby'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.push('/report/$gameId'),
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Report Player'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
