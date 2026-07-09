import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../game/presentation/providers/game_providers.dart';
import '../../domain/entities/room.dart';
import '../providers/room_providers.dart';

class WaitingRoomPage extends ConsumerStatefulWidget {
  final String roomCode;
  const WaitingRoomPage({super.key, required this.roomCode});

  @override
  ConsumerState<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends ConsumerState<WaitingRoomPage> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final roomAsync = ref.watch(roomStreamProvider(widget.roomCode));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(roomActionsProvider).cancelRoom(widget.roomCode);
            context.pop();
          },
        ),
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
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
        data: (room) {
          final isHost = room.hostId == player?.id;
          final hasOpponent = room.guestId != null;

          if (room.status == RoomStatus.playing && room.gameId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.pushReplacement('/game/${room.gameId}');
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (hasOpponent && room.gameId == null && isHost && !_starting) {
            _startRandomGame(room);
          }

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasOpponent
                          ? Icons.check_circle
                          : Icons.hourglass_empty,
                      size: 64,
                      color: hasOpponent
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      hasOpponent
                          ? 'Opponent Joined!'
                          : 'Waiting for opponent...',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Share this code',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            widget.roomCode,
                            style: const TextStyle(
                              fontSize: 36,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.roomCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    if (_starting) ...[
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text('Starting game...',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                    const SizedBox(height: 48),
                    TextButton(
                      onPressed: () {
                        ref.read(roomActionsProvider).cancelRoom(widget.roomCode);
                        context.go('/lobby');
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startRandomGame(Room room) async {
    setState(() => _starting = true);

    try {
      final firestore = ref.read(firestoreDataSourceProvider);
      final objects = await firestore.getObjectsByCategory(room.categoryId);
      if (objects.length < 2) {
        throw Exception('Not enough objects in category');
      }

      final shuffled = List<Map<String, dynamic>>.from(objects)..shuffle(Random());
      final p1ObjectId = shuffled[0]['id'] as String;
      final p2ObjectId = shuffled[1]['id'] as String;

      final rtdb = ref.read(rtdbDataSourceProvider);
      await rtdb.updateRoom(widget.roomCode, {
        'p1ObjectId': p1ObjectId,
        'p2ObjectId': p2ObjectId,
      });

      final gameId = await ref.read(gameActionsProvider).startGame(
            roomCode: widget.roomCode,
            categoryId: room.categoryId,
            player1Id: room.hostId,
            player2Id: room.guestId!,
            p1ObjectId: p1ObjectId,
            p2ObjectId: p2ObjectId,
          );

      await rtdb.updateRoom(widget.roomCode, {
        'gameId': gameId,
        'status': 'playing',
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start game: $e')),
        );
        setState(() => _starting = false);
      }
    }
  }

}
