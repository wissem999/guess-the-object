import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class WaitingRoomPage extends ConsumerWidget {
  final String roomCode;
  const WaitingRoomPage({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              const SizedBox(height: 32),
              const Text(
                'Waiting for opponent...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Room Code: $roomCode',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Share this code with a friend\nor wait for a quick match',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
