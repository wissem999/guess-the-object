import 'dart:async';
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
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _markActive();
  }

  Future<void> _markActive() async {
    try {
      final player = ref.read(authStateProvider).valueOrNull;
      if (player == null) return;
      final rtdb = ref.read(gameRTDBDataSourceProvider);
      final gameSnap = await rtdb.getGameSnapshot(widget.gameId);
      if (gameSnap == null) return;
      final player1Id = gameSnap['player1Id'] as String;
      await rtdb.cancelGameOnDisconnect(widget.gameId);
      await rtdb.setPlayerActive(widget.gameId, player.id, player1Id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final gameAsync = ref.watch(gameStreamProvider(widget.gameId));

    return gameAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: const Center(
          child: Text('Loading game...', style: TextStyle(fontSize: 16)),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/lobby'),
                child: const Text('Back to Lobby'),
              ),
            ],
          ),
        ),
      ),
      data: (game) {
        if (game.phase == GamePhase.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.pushReplacement('/result/${widget.gameId}');
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Game')),
            body: const Center(
              child: Text('Game over!', style: TextStyle(fontSize: 16)),
            ),
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

        final opponentId = game.player1Id == player?.id ? game.player2Id : game.player1Id;
        final isOpponentActive = game.player1Id == player?.id ? game.p2Active : game.p1Active;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Game'),
            actions: [
              _ConnectionIndicator(isOpponentActive: isOpponentActive),
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
                    _OpponentAvatar(opponentId: opponentId),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OpponentName(opponentId: opponentId),
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
              if (!isOpponentActive)
                _DisconnectedBanner(
                  game: game,
                  currentPlayerId: player?.id ?? '',
                  onReconnect: _markActive,
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
          Icon(Icons.hourglass_top, size: 18, color: AppTheme.warning),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
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
                    onPressed: () async {
                      try {
                        await ref
                            .read(gameActionsProvider)
                            .confirmGuess(widget.gameId, true);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to confirm: $e'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
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
                    onPressed: () async {
                      try {
                        await ref
                            .read(gameActionsProvider)
                            .confirmGuess(widget.gameId, false);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to confirm: $e'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
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

  void _submitQuestion(GameState game, String playerId) async {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await ref
          .read(gameActionsProvider)
          .submitTurn(widget.gameId, playerId, text);
      _questionCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send question: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _submitAnswer(GameState game, String turnKey, String playerId) async {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await ref
          .read(gameActionsProvider)
          .submitAnswer(widget.gameId, turnKey, text);
      _questionCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send answer: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
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
            onPressed: () async {
              final guess = ctrl.text.trim();
              if (guess.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(gameActionsProvider)
                      .makeGuess(widget.gameId, playerId, guess);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit guess: $e'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
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

class _ConnectionIndicator extends ConsumerWidget {
  final bool isOpponentActive;
  const _ConnectionIndicator({required this.isOpponentActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = isOpponentActive ? AppTheme.success : AppTheme.error;
    final icon = isOpponentActive ? Icons.wifi : Icons.wifi_off;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            isOpponentActive ? 'Online' : 'Reconnecting',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisconnectedBanner extends ConsumerStatefulWidget {
  final GameState game;
  final String currentPlayerId;
  final VoidCallback onReconnect;
  const _DisconnectedBanner({required this.game, required this.currentPlayerId, required this.onReconnect});

  @override
  ConsumerState<_DisconnectedBanner> createState() => _DisconnectedBannerState();
}

class _DisconnectedBannerState extends ConsumerState<_DisconnectedBanner> {
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          _autoWin();
        }
      });
    });
  }

  Future<void> _autoWin() async {
    try {
      await ref.read(gameActionsProvider).forfeitGame(
        widget.game.gameId,
        widget.currentPlayerId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim win: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: AppTheme.error.withValues(alpha: 0.15),
        child: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.error, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Opponent left — you win!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppTheme.warning.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Opponent disconnected — win in ${_secondsLeft}s',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: _secondsLeft / 60,
              color: AppTheme.warning,
              backgroundColor: AppTheme.warning.withValues(alpha: 0.2),
            ),
          ),
        ],
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
