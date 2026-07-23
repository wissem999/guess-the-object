import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../lobby/data/datasources/category_datasource.dart';
import '../../../ranking/domain/entities/elo_calculator.dart';
import '../../domain/entities/game_state.dart';
import '../providers/game_providers.dart';

class _TierChangeDisplay extends StatelessWidget {
  final int ratingChange;
  final int currentRating;
  final String tier;

  const _TierChangeDisplay({
    required this.ratingChange,
    required this.currentRating,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ELOCalculator.tierProgress(currentRating);
    final nextThreshold = ELOCalculator.nextTierThreshold(currentRating);
    final progressColor = ratingChange >= 0 ? AppTheme.success : AppTheme.error;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tier, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (nextThreshold != 999999) ...[
              const Text(' → ', style: TextStyle(fontSize: 14)),
              Text(
                ELOCalculator.calculateTier(nextThreshold),
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [progressColor.withValues(alpha: 0.7), progressColor],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$currentRating / $nextThreshold',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _ObjectReveal extends StatelessWidget {
  final GameState game;
  final String playerId;
  final FirestoreDataSource firestore;

  const _ObjectReveal({
    required this.game,
    required this.playerId,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final isP1 = game.player1Id == playerId;
    final myObjectId = isP1 ? game.p1ObjectId : game.p2ObjectId;
    final oppObjectId = isP1 ? game.p2ObjectId : game.p1ObjectId;

    return FutureBuilder<Map<String, String>>(
      future: Future.wait([
        firestore.getObjectById(myObjectId),
        firestore.getObjectById(oppObjectId),
      ]).then((results) => {
            'my': results[0]?['name'] as String? ?? '???',
            'opp': results[1]?['name'] as String? ?? '???',
          }),
      builder: (ctx, snap) {
        final myName = snap.data?['my'] ?? '...';
        final oppName = snap.data?['opp'] ?? '...';
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            children: [
              Text('Your Object',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  )),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(myName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 16),
              Text("Opponent's Object",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  )),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(oppName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ResultPage extends ConsumerWidget {
  final String gameId;
  const ResultPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final gameAsync = ref.watch(gameStreamProvider(gameId));

    return gameAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (game) {
        final didWin = game.winnerId == player?.id;
        final change = game.winnerId != null && player != null
            ? ELOCalculator.getRatingChange(
                game.winnerId == player.id
                    ? (player.rating)
                    : (player.rating - 100),
                game.winnerId != player.id
                    ? (player.rating)
                    : (player.rating - 100),
              )
            : 0;
        final ratingChange = didWin ? change : -change;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
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
                        didWin
                            ? Icons.emoji_events
                            : Icons.sentiment_dissatisfied,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ratingChange >= 0 ? '+' : ''}$ratingChange Rating',
                        style: TextStyle(
                          color: didWin ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (player != null) ...[
                      const SizedBox(height: 16),
                      _TierChangeDisplay(
                        ratingChange: ratingChange,
                        currentRating: player.rating,
                        tier: ELOCalculator.calculateTier(player.rating),
                      ),
                    ],
                    if (game.p1ObjectId.isNotEmpty && game.p2ObjectId.isNotEmpty)
                      _ObjectReveal(
                        game: game,
                        playerId: player?.id ?? '',
                        firestore: ref.read(firestoreDataSourceProvider),
                      ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/lobby'),
                        icon: const Icon(Icons.home),
                        label: const Text('Back to Lobby'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        final opponentId = game.player1Id == player?.id
                            ? game.player2Id
                            : game.player1Id;
                        context.push(
                            '/report/$gameId/$opponentId/${game.categoryId}');
                      },
                      icon: const Icon(Icons.flag, size: 18),
                      label: const Text('Report Player'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
