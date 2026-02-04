import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/src/data/repositories/bug_report_repository.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:shake/shake.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BugReporterWrapper extends StatefulWidget {
  const BugReporterWrapper({
    required this.child,
    this.enabled = !kReleaseMode,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<BugReporterWrapper> createState() => _BugReporterWrapperState();
}

class _BugReporterWrapperState extends State<BugReporterWrapper> {
  ShakeDetector? _detector;

  @override
  void initState() {
    super.initState();
    if (widget.enabled &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      _detector = ShakeDetector.autoStart(
        onPhoneShake: (ShakeEvent event) {
          unawaited(_showReportDialog());
        },
      );
    }
  }

  @override
  void dispose() {
    _detector?.stopListening();
    super.dispose();
  }

  Future<void> _showReportDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var isLoading = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('🐞 Bug Report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Shake detected! Send logs to developers?'),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (What happened?)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        try {
                          final logs = Log.export();
                          final repo = BugReportRepository(
                            Supabase.instance.client,
                          );
                          await repo.reportBug(
                            title: titleController.text.isEmpty
                                ? 'User Report'
                                : titleController.text,
                            description: descController.text,
                            logs: logs,
                          );

                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bug reported successfully! 🚀'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } on Exception catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to report: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: const Text('Send Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled &&
            (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.macOS ||
                defaultTargetPlatform == TargetPlatform.windows))
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              type: MaterialType.transparency,
              child: FloatingActionButton(
                mini: true,
                onPressed: _showReportDialog,
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.bug_report),
              ),
            ),
          ),
      ],
    );
  }
}
