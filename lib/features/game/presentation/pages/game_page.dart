import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class GamePage extends ConsumerStatefulWidget {
  final String gameId;
  const GamePage({super.key, required this.gameId});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  final _questionCtrl = TextEditingController();
  bool _isMyTurn = true;
  final List<Map<String, String>> _myQuestions = [];
  final List<Map<String, String>> _opponentQuestions = [];

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isMyTurn ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isMyTurn ? 'Your Turn' : 'Their Turn',
              style: TextStyle(
                color: _isMyTurn ? AppTheme.success : AppTheme.warning,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Opponent info
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.darkBackground.withValues(alpha: 0.03),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Opponent', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'Tier: Silver',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.flag, size: 18),
                  label: const Text('Guess', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),

          // Turn History
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // My Questions
                if (_myQuestions.isNotEmpty) ...[
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
                  ..._myQuestions.map((q) => _buildQuestionCard(q, isMine: true)),
                  const SizedBox(height: 16),
                ],

                // Their Questions
                if (_opponentQuestions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Opponent\'s Questions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                  ..._opponentQuestions.map((q) => _buildQuestionCard(q, isMine: false)),
                ],

                if (_myQuestions.isEmpty && _opponentQuestions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No questions yet. Start by asking!'),
                    ),
                  ),
              ],
            ),
          ),

          // Question input
          Container(
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
              children: [
                if (_isMyTurn) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _questionCtrl,
                          decoration: InputDecoration(
                            hintText: 'Ask a question...',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _submitQuestion,
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
                      _quickAnswerBtn('IDK', AppTheme.warning),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        const Text('Waiting for opponent...'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, String> q, {required bool isMine}) {
    final isQuestion = q.containsKey('question');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMine ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isQuestion ? 'Q: ${q['question']}' : 'A: ${q['answer']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (q.containsKey('answer') && isQuestion)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'A: ${q['answer']}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
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
      width: 60,
      child: OutlinedButton(
        onPressed: _isMyTurn ? () => _questionCtrl.text = label.toLowerCase() : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _submitQuestion() {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _myQuestions.add({'question': text});
      _isMyTurn = false;
      _questionCtrl.clear();
    });
  }
}
