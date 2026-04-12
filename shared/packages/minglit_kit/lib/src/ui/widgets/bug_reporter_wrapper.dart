import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/repositories/bug_report_repository.dart';
import 'package:minglit_kit/src/data/repositories/storage_repository.dart';
import 'package:minglit_kit/src/data/services/bug_report_collector.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/utils/environment_info.dart';
import 'package:minglit_kit/src/utils/layout_dump.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:minglit_kit/src/utils/qa_bug_report_channel.dart';

/// Dev-only: callback registered by [BugReporterWrapper] so that any screen
/// can trigger the bug report dialog via [BugReportAction].
// Fix #1285: FAB 제거 후 앱바 액션 버튼 지원 — callback을 Provider로 노출
final bugReporterCallbackProvider =
    NotifierProvider<_BugReporterCallbackNotifier, Future<void> Function()?>(
      _BugReporterCallbackNotifier.new,
    );

class _BugReporterCallbackNotifier extends Notifier<Future<void> Function()?> {
  @override
  Future<void> Function()? build() => null;

  /// Registers or clears the bug report callback.
  ///
  /// A setter is not used here: the paired getter required by
  /// `avoid_setters_without_getters` would add unnecessary boilerplate.
  // ignore: use_setters_to_change_properties
  void update(Future<void> Function()? callback) => state = callback;
}

/// Wraps [child] with bug reporting UI.
// Fix #412: ConsumerStatefulWidget 전환 — Supabase 직접 접근 제거, Riverpod Provider 주입
class BugReporterWrapper extends ConsumerStatefulWidget {
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
  /// so its own `context` cannot reach a `Navigator` ancestor.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Whether bug reporting is enabled.
  final bool enabled;

  @override
  ConsumerState<BugReporterWrapper> createState() => _BugReporterWrapperState();
}

class _BugReporterWrapperState extends ConsumerState<BugReporterWrapper> {
  bool _isReportOpen = false;
  bool _isCapturing = false;
  final GlobalKey _boundaryKey = GlobalKey();
  String? _screenshotUrl;
  Map<String, dynamic>? _environmentInfo;
  String? _layoutDumpUrl;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      QaBugReportChannel.initialize(
        BugReportCollector(boundaryKey: _boundaryKey),
      );
    }
  }

  /// Returns a [BuildContext] that has a [Navigator] ancestor.
  ///
  /// Prefers the overlay context from `widget.navigatorKey` (which sits
  /// below the [Navigator]), falling back to [context] for desktop/web
  /// where the FAB already has a valid context.
  BuildContext? get _dialogContext =>
      widget.navigatorKey?.currentState?.overlay?.context ?? context;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(bugReporterCallbackProvider.notifier)
            .update(_showReportDialog);
      }
    });
  }

  @override
  void dispose() {
    // Note: the callback intentionally holds a reference to this state's
    // _showReportDialog, which guards unmounted access at its top.
    // Clearing the provider here is unsafe in Riverpod v3 (modifying providers
    // during finalization is forbidden), so cleanup is omitted.
    // BugReporterWrapper lives for the app's lifetime, so stale callbacks
    // are not a concern in practice.
    super.dispose();
  }

  /// Captures a screenshot of the wrapped child and uploads it to Storage.
  ///
  /// Returns the public URL on success, or null on failure (best-effort).
  /// Always returns null on web (not supported).
  Future<String?> _captureScreenshot() async {
    if (kIsWeb) return null;
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      // Fix #412: StorageRepository 직접 생성 → Provider 주입
      final url = await ref
          .read(storageRepositoryProvider)
          .uploadBytes(
            bytes: bytes,
            bucket: 'bug-report-attachments',
            pathPrefix: 'screenshots',
          );
      return url;
    } on Exception catch (e) {
      Log.e('Screenshot capture failed (best-effort)', e);
      return null;
    }
  }

  Future<void> _showReportDialog() async {
    if (!mounted) return;
    // Fix #51: return early if dialog is already open — do not dismiss+reopen
    if (_isReportOpen || _isCapturing) return;
    // Capture context BEFORE async gap
    final ctx = _dialogContext;
    if (ctx == null) return;

    // Fix #147: show progress on FAB while capturing screenshot/env info
    setState(() => _isCapturing = true);

    // Capture screenshot AND environment info in parallel BEFORE opening sheet
    final results = await Future.wait([
      _captureScreenshot(),
      collectEnvironmentInfo(),
      captureLayoutDump(),
    ]);

    if (!mounted) {
      _isCapturing = false;
      return;
    }
    setState(() => _isCapturing = false);
    if (!ctx.mounted) return;

    final screenshotUrl = results[0] as String?;
    final environment = results[1] as Map<String, dynamic>?;
    final layoutDump = results[2] as String?;

    // Upload layout dump to Storage (best-effort)
    String? layoutDumpUrl;
    if (layoutDump != null) {
      try {
        // Fix #412: StorageRepository 직접 생성 → Provider 주입
        layoutDumpUrl = await ref
            .read(storageRepositoryProvider)
            .uploadBytes(
              bytes: Uint8List.fromList(utf8.encode(layoutDump)),
              bucket: 'bug-report-attachments',
              pathPrefix: 'layout-dumps',
              contentType: 'text/plain',
              extension: '.txt',
            );
      } on Object catch (e) {
        Log.e('Layout dump upload failed (best-effort)', e);
      }
    }

    setState(() {
      _screenshotUrl = screenshotUrl;
      _environmentInfo = environment;
      _layoutDumpUrl = layoutDumpUrl;
    });

    final titleController = TextEditingController();
    final descController = TextEditingController();
    var isLoading = false;

    _isReportOpen = true;
    try {
      if (!ctx.mounted) return;
      await showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: MinglitSpacing.medium,
                right: MinglitSpacing.medium,
                top: MinglitSpacing.medium,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    MinglitSpacing.medium,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(
                          bottom: MinglitSpacing.medium,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title
                    Text(
                      '🐞 Bug Report',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    // Screenshot preview (if available)
                    if (_screenshotUrl != null) ...[
                      const SizedBox(height: MinglitSpacing.small),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _screenshotUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 60,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: MinglitSpacing.xsmall),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              setSheetState(() => _screenshotUrl = null),
                          child: Text(
                            'Remove screenshot',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: MinglitSpacing.medium),
                    // Title field
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    // Description field
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (What happened?)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    // Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: MinglitSpacing.small),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setSheetState(() => isLoading = true);
                                    try {
                                      final logs = Log.export();
                                      // Fix #412: Provider 주입
                                      final repo = BugReportRepository(
                                        ref.read(
                                          supabaseClientProvider,
                                        ),
                                      );
                                      await repo.reportBug(
                                        title: titleController.text.isEmpty
                                            ? 'User Report'
                                            : titleController.text,
                                        description: descController.text,
                                        logs: logs,
                                        screenshotUrl: _screenshotUrl,
                                        environment: _environmentInfo,
                                        platform: defaultTargetPlatform.name,
                                        layoutDumpUrl: _layoutDumpUrl,
                                      );
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Bug reported successfully! 🚀',
                                          ),
                                          backgroundColor:
                                              MinglitColors.success,
                                        ),
                                      );
                                    } on Exception catch (e) {
                                      if (!context.mounted) return;
                                      setSheetState(() => isLoading = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to report: $e'),
                                          backgroundColor: MinglitColors.error,
                                        ),
                                      );
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: MinglitCircularProgressIndicator(),
                                  )
                                : const Text('Send Report'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      _isReportOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: _boundaryKey, child: widget.child);
  }
}

/// Action button for the app bar that triggers the bug reporter.
///
/// Only renders in non-release mode when [BugReporterWrapper] is active.
// Fix #1285: FAB 대체 — 앱바 액션 버튼 (dev only)
class BugReportAction extends ConsumerWidget {
  /// Creates a bug report action button.
  const BugReportAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kReleaseMode) return const SizedBox.shrink();
    final showDialog = ref.watch(bugReporterCallbackProvider);
    if (showDialog == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.bug_report),
      color: MinglitColors.error,
      tooltip: 'Bug Report',
      onPressed: showDialog,
    );
  }
}
