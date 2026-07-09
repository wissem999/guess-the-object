import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/turn.dart';
import '../providers/game_providers.dart';

class GamePage extends ConsumerStatefulWidget {
  final String gameId;
  const GamePage({super.key, required this.gameId});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  final _questionCtrl = TextEditingController();

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final gameAsync = ref.watch(gameStreamProvider(widget.gameId));

    return gameAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (game) {
        if (game.phase == GamePhase.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.pushReplacement('/result/${widget.gameId}');
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Game')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final isMyTurn = game.currentTurn == player?.id;
        final isMyGuess = game.guess?.playerId == player?.id;
        final opponentGuessed = game.phase == GamePhase.guessing && !isMyGuess;

        final myQuestions = game.turns
            .where((t) => t.playerId == player?.id)
            .toList();
        final pendingIdx = game.turns.lastIndexWhere((t) => t.answer == null);
        final needsAnswer = game.phase == GamePhase.playing &&
            pendingIdx >= 0 &&
            game.turns[pendingIdx].playerId != player?.id;
        final canAsk = isMyTurn && !needsAnswer && game.phase == GamePhase.playing;
        final pendingTurnKey = needsAnswer ? 'turn_$pendingIdx' : null;
        final pendingQuestion = needsAnswer ? game.turns[pendingIdx].question : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Game'),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isMyTurn
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isMyTurn ? 'Your Turn' : 'Their Turn',
                  style: TextStyle(
                    color: isMyTurn ? AppTheme.success : AppTheme.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: AppTheme.darkBackground.withValues(alpha: 0.03),
                child: Row(
                  children: [
                    _OpponentAvatar(opponentId: game.player1Id == player?.id ? game.player2Id : game.player1Id),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OpponentName(opponentId: game.player1Id == player?.id ? game.player2Id : game.player1Id),
                          _MyObjectName(objectId: game.player1Id == player?.id ? game.p1ObjectId : game.p2ObjectId),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: game.phase == GamePhase.playing
                          ? () => _showGuessDialog(player?.id ?? '')
                          : null,
                      icon: const Icon(Icons.flag, size: 18),
                      label: Text(
                        isMyGuess ? 'Guessed!' : 'Make a Guess',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: isMyGuess
                            ? AppTheme.textSecondary
                            : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              if (opponentGuessed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.help, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Opponent guessed: "${game.guess!.guessedObject}"',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (myQuestions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'My Questions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      ...myQuestions.map((t) => _buildTurnCard(t)),
                    ],
                    if (myQuestions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No questions yet. Start by asking!'),
                        ),
                      ),
                  ],
                ),
              ),
              _buildBottomBar(
                canAsk: canAsk,
                needsAnswer: needsAnswer,
                pendingTurnKey: pendingTurnKey,
                pendingQuestion: pendingQuestion,
                game: game,
                playerId: player?.id ?? '',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar({
    required bool canAsk,
    required bool needsAnswer,
    required String? pendingTurnKey,
    required String? pendingQuestion,
    required GameState game,
    required String playerId,
  }) {
    if (game.phase == GamePhase.guessing) {
      if (game.guess?.playerId != playerId) {
        return _buildConfirmBar(game.guess!);
      }
      return _buildWaitingBar('Waiting for opponent to confirm...');
    }

    if (needsAnswer && pendingTurnKey != null) {
      return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingQuestion != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Opponent asks:',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text(pendingQuestion,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionCtrl,
                    decoration: InputDecoration(
                      hintText: 'Answer the question...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () =>
                            _submitAnswer(game, pendingTurnKey, playerId),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickAnswerBtn('Yes', AppTheme.success),
                _quickAnswerBtn('No', AppTheme.error),
              ],
            ),
          ],
        ),
      );
    }

    if (canAsk) {
      return Container(
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
              child: TextField(
                controller: _questionCtrl,
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _submitQuestion(game, playerId),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildWaitingBar('Waiting for opponent...');
  }

  Widget _buildWaitingBar(String message) {
    return Container(
      width: double.infinity,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildConfirmBar(Guess guess) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Did they guess "${guess.guessedObject}"?',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(gameActionsProvider)
                        .confirmGuess(widget.gameId, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Yes — I Lose'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(gameActionsProvider)
                        .confirmGuess(widget.gameId, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('No — They Lose'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitQuestion(GameState game, String playerId) {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;
    ref
        .read(gameActionsProvider)
        .submitTurn(widget.gameId, playerId, text);
    _questionCtrl.clear();
  }

  void _submitAnswer(GameState game, String turnKey, String playerId) {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;
    ref
        .read(gameActionsProvider)
        .submitAnswer(widget.gameId, turnKey, text);
    _questionCtrl.clear();
  }

  void _showGuessDialog(String playerId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Make a Guess'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Type the object name...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final guess = ctrl.text.trim();
              if (guess.isNotEmpty) {
                ref
                    .read(gameActionsProvider)
                    .makeGuess(widget.gameId, playerId, guess);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guess!'),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnCard(Turn turn) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q: ${turn.question ?? "..."}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (turn.answer != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'A: ${turn.answer}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Waiting for answer...',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAnswerBtn(String label, Color color) {
    return SizedBox(
      width: 72,
      child: OutlinedButton(
        onPressed: () => _questionCtrl.text = label.toLowerCase(),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _OpponentAvatar extends ConsumerWidget {
  final String opponentId;
  const _OpponentAvatar({required this.opponentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDtoStreamProvider(opponentId));
    return playerAsync.when(
      data: (p) => CircleAvatar(
        radius: 20,
        backgroundImage:
            p?.photoUrl != null ? NetworkImage(p!.photoUrl!) : null,
        child: p?.photoUrl == null ? const Icon(Icons.person) : null,
      ),
      error: (_, _) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
      loading: () => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
    );
  }
}

class _OpponentName extends ConsumerWidget {
  final String opponentId;
  const _OpponentName({required this.opponentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDtoStreamProvider(opponentId));
    return playerAsync.when(
      data: (p) => Text(p?.name ?? 'Opponent',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      error: (_, _) =>
          const Text('Opponent', style: TextStyle(fontWeight: FontWeight.bold)),
      loading: () =>
          const Text('Opponent', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _MyObjectName extends ConsumerWidget {
  final String objectId;
  const _MyObjectName({required this.objectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreDataSourceProvider).getObjectById(objectId),
      builder: (ctx, snap) {
        final name = snap.data?['name'] as String? ?? '...';
        return Row(
          children: [
            Text('Your word: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                )),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}
