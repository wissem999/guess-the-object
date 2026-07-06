import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ReportPage extends ConsumerStatefulWidget {
  final String matchId;
  const ReportPage({super.key, required this.matchId});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  final _descCtrl = TextEditingController();
  String? _selectedReason;

  final _reasons = [
    'intentional_wrong_answer',
    'bad_words',
    'cheating',
    'other',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Player')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Why are you reporting this player?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Reason picker
          ..._reasons.map((reason) => RadioListTile<String>(
                title: Text(reason.replaceAll('_', ' ').toUpperCase()),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (v) => setState(() => _selectedReason = v),
              )),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Describe what happened...',
            ),
          ),
          const SizedBox(height: 16),

          // Match info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Match ID: ${widget.matchId}',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReason == null
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted. Admin will review.')),
                      );
                      context.pop();
                    },
              child: const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }
}
