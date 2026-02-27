import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/src/data/repositories/bug_report_repository.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:shake/shake.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps [child] with bug reporting UI and shake detection.
class BugReporterWrapper extends StatefulWidget {
  /// Creates a bug reporter wrapper.
  const BugReporterWrapper({
    required this.child,
    this.navigatorKey,
    this.enabled = !kReleaseMode,
    super.key,
  });

  /// The widget subtree to wrap.
  final Widget child;

  /// Navigator key used to obtain a context below the [Navigator].
  ///
  /// Required on mobile because [BugReporterWrapper] sits above the
  /// [Navigator] in the widget tree (inside [MaterialApp.builder]),
  /// so its own [context] cannot reach a [Navigator] ancestor.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Whether bug reporting is enabled.
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
        onPhoneShake: (event) {
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

  /// Returns a [BuildContext] that has a [Navigator] ancestor.
  ///
  /// Prefers the overlay context from [widget.navigatorKey] (which sits
  /// below the [Navigator]), falling back to [context] for desktop/web
  /// where the FAB already has a valid context.
  BuildContext? get _dialogContext =>
      widget.navigatorKey?.currentState?.overlay?.context ?? context;

  Future<void> _showReportDialog() async {
    if (!mounted) return;
    final ctx = _dialogContext;
    if (ctx == null) return;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    var isLoading = false;

    await showDialog<void>(
      context: ctx,
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
                              backgroundColor: MinglitColors.success,
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
                              backgroundColor: MinglitColors.error,
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
                backgroundColor: MinglitColors.error,
                child: const Icon(Icons.bug_report),
              ),
            ),
          ),
      ],
    );
  }
}
