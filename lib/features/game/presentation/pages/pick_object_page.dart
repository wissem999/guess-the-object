import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../lobby/presentation/providers/lobby_providers.dart';
import '../../../room/presentation/providers/room_providers.dart';
import '../../presentation/providers/game_providers.dart';

class PickObjectPage extends ConsumerStatefulWidget {
  final String roomCode;
  const PickObjectPage({super.key, required this.roomCode});

  @override
  ConsumerState<PickObjectPage> createState() => _PickObjectPageState();
}

class _PickObjectPageState extends ConsumerState<PickObjectPage> {
  bool _picked = false;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(authStateProvider).valueOrNull;
    final roomAsync = ref.watch(roomStreamProvider(widget.roomCode));
    final categoryId = ref.watch(selectedCategoryProvider);
    final objectsAsync = ref.watch(objectsByCategoryProvider(categoryId ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Pick Your Object')),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room.status.name == 'playing' && room.gameId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.pushReplacement('/game/${room.gameId}');
            });
            return const Center(child: CircularProgressIndicator());
          }

          final isHost = room.hostId == player?.id;
          final myPick =
              isHost ? room.p1ObjectId : room.p2ObjectId;
          final oppPick =
              isHost ? room.p2ObjectId : room.p1ObjectId;
          final opponentName = isHost ? 'Guest' : 'Host';

          if (room.bothObjectsPicked && room.gameId == null && isHost) {
            _startGame(room.code, room.categoryId, room.hostId,
                room.guestId!, room.p1ObjectId!, room.p2ObjectId!);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  myPick != null
                      ? 'Object selected!'
                      : 'Select your secret object',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  myPick != null
                      ? 'Waiting for opponent to pick...'
                      : 'Your opponent will try to guess this',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      myPick != null ? Icons.check_circle : Icons.hourglass_empty,
                      size: 16,
                      color: myPick != null ? AppTheme.success : AppTheme.warning,
                    ),
                    const SizedBox(width: 6),
                    Text('You: ${myPick != null ? "Picked" : "Not picked"}',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 16),
                    Icon(
                      oppPick != null ? Icons.check_circle : Icons.hourglass_empty,
                      size: 16,
                      color: oppPick != null ? AppTheme.success : AppTheme.warning,
                    ),
                    const SizedBox(width: 6),
                    Text('$opponentName: ${oppPick != null ? "Picked" : "Not picked"}',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: objectsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (objects) {
                      if (objects.isEmpty) {
                        return const Center(
                            child: Text('No objects available'));
                      }
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: objects.length,
                        itemBuilder: (context, index) {
                          final obj = objects[index];
                          final alreadyPicked = myPick != null;
                          return Card(
                            color: alreadyPicked
                                ? AppTheme.surface
                                : null,
                            child: InkWell(
                              onTap: alreadyPicked
                                  ? null
                                  : () => _pickObject(
                                      obj.id, isHost, player?.id),
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    obj.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: alreadyPicked
                                          ? AppTheme.textSecondary
                                          : null,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickObject(
      String objectId, bool isHost, String? playerId) async {
    if (playerId == null || _picked) return;
    _picked = true;

    final field = isHost ? 'p1ObjectId' : 'p2ObjectId';
    await ref.read(rtdbDataSourceProvider).updateRoom(
          widget.roomCode,
          {field: objectId},
        );
  }

  void _startGame(String roomCode, String categoryId, String player1Id,
      String player2Id, String p1ObjectId, String p2ObjectId) async {
    try {
      final gameId = await ref.read(gameActionsProvider).startGame(
            roomCode: roomCode,
            categoryId: categoryId,
            player1Id: player1Id,
            player2Id: player2Id,
            p1ObjectId: p1ObjectId,
            p2ObjectId: p2ObjectId,
          );

      await ref.read(rtdbDataSourceProvider).updateRoom(roomCode, {
        'gameId': gameId,
        'status': 'playing',
      });
    } catch (_) {}
  }
}
