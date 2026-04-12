import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:minglit_kit/src/data/repositories/bug_report_repository.dart';
import 'package:minglit_kit/src/data/repositories/storage_repository.dart';
import 'package:minglit_kit/src/utils/environment_info.dart';
import 'package:minglit_kit/src/utils/layout_dump.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Collects bug report data (screenshot, layout dump, environment info, logs)
/// and submits it via [BugReportRepository].
///
/// Extracted from [BugReporterWrapper] so that programmatic callers
/// (e.g. [QaBugReportChannel]) can trigger a report without UI interaction.
class BugReportCollector {
  /// Creates a [BugReportCollector] bound to [boundaryKey].
  ///
  /// [boundaryKey] must be attached to a [RepaintBoundary] widget.
  const BugReportCollector({required this.boundaryKey});

  /// The key attached to the [RepaintBoundary] for screenshot capture.
  final GlobalKey boundaryKey;

  /// Captures a screenshot of the widget subtree under [boundaryKey].
  ///
  /// Returns the public Storage URL on success, or null on failure
  /// (best-effort — never throws).
  Future<String?> captureScreenshot() async {
    if (kIsWeb) return null;
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      return StorageRepository().uploadBytes(
        bytes: bytes,
        bucket: 'bug-report-attachments',
        pathPrefix: 'screenshots',
      );
    } on Exception catch (e) {
      Log.e('Screenshot capture failed (best-effort)', e);
      return null;
    }
  }

  /// Captures the layout dump and uploads it to Storage.
  ///
  /// Returns the public Storage URL on success, or null on failure
  /// (best-effort — never throws).
  Future<String?> captureAndUploadLayoutDump() async {
    final layoutDump = await captureLayoutDump();
    if (layoutDump == null) return null;
    try {
      return await StorageRepository().uploadBytes(
        bytes: Uint8List.fromList(utf8.encode(layoutDump)),
        bucket: 'bug-report-attachments',
        pathPrefix: 'layout-dumps',
        contentType: 'text/plain',
        extension: '.txt',
      );
    } on Object catch (e) {
      Log.e('Layout dump upload failed (best-effort)', e);
      return null;
    }
  }

  /// Collects all artifacts in parallel and submits the bug report.
  ///
  /// Prepends `[QA]` to [title] when [scenarioId] or [sessionId] is provided
  /// to distinguish automated QA reports from manual shake-triggered ones.
  Future<void> submitReport({
    required String title,
    required String description,
    String? scenarioId,
    String? sessionId,
  }) async {
    final results = await Future.wait([
      captureScreenshot(),
      collectEnvironmentInfo(),
      captureAndUploadLayoutDump(),
    ]);

    final screenshotUrl = results[0] as String?;
    final environment = results[1] as Map<String, dynamic>?;
    final layoutDumpUrl = results[2] as String?;
    final logs = Log.export();

    final effectiveTitle = (scenarioId != null || sessionId != null)
        ? '[QA] $title'
        : title;
    final effectiveDescription = _buildDescription(
      description,
      scenarioId,
      sessionId,
    );

    final repo = BugReportRepository(Supabase.instance.client);
    await repo.reportBug(
      title: effectiveTitle,
      description: effectiveDescription,
      logs: logs,
      screenshotUrl: screenshotUrl,
      environment: environment,
      platform: defaultTargetPlatform.name,
      layoutDumpUrl: layoutDumpUrl,
    );
  }

  String _buildDescription(
    String description,
    String? scenarioId,
    String? sessionId,
  ) {
    final buffer = StringBuffer(description);
    if (scenarioId != null && scenarioId.isNotEmpty) {
      buffer.write('\n\nScenario: $scenarioId');
    }
    if (sessionId != null && sessionId.isNotEmpty) {
      buffer.write('\nSession: $sessionId');
    }
    return buffer.toString();
  }
}
