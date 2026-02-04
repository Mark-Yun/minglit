import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/log.dart';
import '../../data/repositories/bug_report_repository.dart';

class BugReporterWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const BugReporterWrapper({
    super.key,
    required this.child,
    this.enabled = !kReleaseMode, // Default: enabled in debug/profile only
  });

  @override
  State<BugReporterWrapper> createState() => _BugReporterWrapperState();
}

class _BugReporterWrapperState extends State<BugReporterWrapper> {
  ShakeDetector? _detector;

  @override
  void initState() {
    super.initState();
    // Only init shake detector on mobile
    if (widget.enabled &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      _detector = ShakeDetector.autoStart(
        onPhoneShake: () => _showReportDialog(),
        minimumShakeCount: 1,
        shakeSlopTimeMS: 500,
        shakeCountResetTime: 3000,
        shakeThresholdGravity: 2.7,
      );
    }
  }

  @override
  void dispose() {
    _detector?.stopListening();
    super.dispose();
  }

  void _showReportDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    // Auto-fill title with current route or context if possible
    // For now, leave empty

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;

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

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bug reported successfully! 🚀'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to report: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted && Navigator.canPop(context)) {
                            // Ensure dialog logic is handled by pop above
                          }
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
        // FAB for Web or Desktop where shake is not available
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
