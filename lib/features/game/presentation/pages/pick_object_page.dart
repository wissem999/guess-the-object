import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'dart:math';

final _random = Random();
final _dummyObjects = [
  'Elephant', 'Dog', 'Cat', 'Eagle', 'Shark', 'Snake', 'Penguin', 'Lion',
];

class PickObjectPage extends ConsumerWidget {
  final String roomCode;
  const PickObjectPage({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Your Object')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your secret object',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your opponent will try to guess this',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: _dummyObjects.length,
                itemBuilder: (context, index) {
                  final obj = _dummyObjects[index];
                  return Card(
                    child: InkWell(
                      onTap: () {
                        context.push('/game/${roomCode}_${_random.nextInt(1000)}');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Text(
                          obj,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
