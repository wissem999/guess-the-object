import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JoinRoomPage extends ConsumerStatefulWidget {
  const JoinRoomPage({super.key});

  @override
  ConsumerState<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends ConsumerState<JoinRoomPage> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Room')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-character room code',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 32,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'ABC123',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final code = _codeCtrl.text.trim().toUpperCase();
                  if (code.length == 6) {
                    context.push('/waiting-room/$code');
                  }
                },
                child: const Text('Join Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
