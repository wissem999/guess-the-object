import 'package:flutter/material.dart';
import '../../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  static Future<bool> show(BuildContext context, UpdateInfo info) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(updateInfo: info),
    );
    return result ?? false;
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  bool _installing = false;
  double _progress = 0.0;
  String? _errorMessage;

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _progress = 0.0;
      _errorMessage = null;
    });

    final filePath = await UpdateService.downloadApk(
      widget.updateInfo.apkUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;

    if (filePath == null) {
      setState(() {
        _downloading = false;
        _errorMessage = 'Download failed. Check your internet connection and try again.';
      });
      return;
    }

    // Download complete, now install
    setState(() {
      _downloading = false;
      _installing = true;
    });

    final installed = await UpdateService.installApk(filePath);

    if (!mounted) return;

    if (!installed) {
      setState(() {
        _installing = false;
        _errorMessage =
            'Could not open installer. Go to Settings > Security > '
            'Install unknown apps, then allow this app to install.';
      });
      return;
    }

    // Intent launched successfully — app will switch to installer
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_downloading && !_installing,
      child: AlertDialog(
        backgroundColor: const Color(0xFF120A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFF6C4EF8).withValues(alpha: 0.3),
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C4EF8),
                    const Color(0xFF3B82F6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C4EF8).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'New Update Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.updateInfo.updateMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C4EF8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Version ${widget.updateInfo.version}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C4EF8).withValues(alpha: 0.8),
                ),
              ),
            ),
            if (_downloading) ...[
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF6C4EF8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Downloading update...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
            if (_installing) ...[
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF6C4EF8),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Opening installer...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.withValues(alpha: 0.8), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_downloading && !_installing) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Later',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: _startDownload,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C4EF8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Update Now',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (_downloading)
            TextButton(
              onPressed: null,
              child: Text(
                'Downloading...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          if (_errorMessage != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
