import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/report_providers.dart';

class ReportPage extends ConsumerStatefulWidget {
  final String matchId;
  final String reportedPlayerId;
  final String categoryId;
  const ReportPage({
    super.key,
    required this.matchId,
    required this.reportedPlayerId,
    required this.categoryId,
  });

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
          RadioGroup<String>(
            groupValue: _selectedReason,
            onChanged: (v) => setState(() => _selectedReason = v),
            child: Column(
              children: _reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason.replaceAll('_', ' ').toUpperCase()),
                    value: reason,
                  )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Describe what happened...',
            ),
          ),
          const SizedBox(height: 16),
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
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
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
                  : () => _submitReport(context),
              child: const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext context) async {
    final player = ref.read(authStateProvider).valueOrNull;
    if (player == null) return;

    try {
      await ref.read(reportActionsProvider).submitReport(
            reporterId: player.id,
            reportedPlayerId: widget.reportedPlayerId,
            matchId: widget.matchId,
            categoryId: widget.categoryId,
            reason: _selectedReason!,
            description: _descCtrl.text.trim(),
            reporterName: player.name,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Report submitted. Admin will review.')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }
}
