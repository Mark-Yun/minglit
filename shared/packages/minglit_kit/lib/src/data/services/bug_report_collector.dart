import 'dart:convert';
import 'dart:io' show Directory, File;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:minglit_kit/minglit_dev.dart' show QaBugReportChannel;
import 'package:minglit_kit/minglit_kit.dart' show BugReporterWrapper;
import 'package:minglit_kit/minglit_ui.dart' show BugReporterWrapper;
import 'package:minglit_kit/src/data/repositories/bug_report_repository.dart';
import 'package:minglit_kit/src/data/repositories/storage_repository.dart';
import 'package:minglit_kit/src/ui/widgets/bug_reporter_wrapper.dart'
    show BugReporterWrapper;
import 'package:minglit_kit/src/utils/environment_info.dart';
import 'package:minglit_kit/src/utils/layout_dump.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:minglit_kit/src/utils/qa_bug_report_channel.dart'
    show QaBugReportChannel;
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
  ///
  /// The optional [storage], [bugReportRepository], and
  /// [environmentInfoCollector] parameters are for testing only — production
  /// code should omit them.
  BugReportCollector({
    required this.boundaryKey,
    @visibleForTesting StorageRepository? storage,
    @visibleForTesting BugReportRepository? bugReportRepository,
    @visibleForTesting Future<Map<String, dynamic>> Function()? environmentInfoCollector,
  }) : _storage = storage,
       _bugReportRepository = bugReportRepository,
       _environmentInfoCollector = environmentInfoCollector;

  /// The key attached to the [RepaintBoundary] for screenshot capture.
  final GlobalKey boundaryKey;

  final StorageRepository? _storage;
  final BugReportRepository? _bugReportRepository;
  final Future<Map<String, dynamic>> Function()? _environmentInfoCollector;

  StorageRepository get _storageInstance => _storage ?? StorageRepository();

  BugReportRepository get _repoInstance =>
      _bugReportRepository ?? BugReportRepository(Supabase.instance.client);

  Future<Map<String, dynamic>> _collectEnv() =>
      _environmentInfoCollector?.call() ?? collectEnvironmentInfo();

  /// Captures raw PNG bytes from the widget subtree under [boundaryKey].
  ///
  /// Returns null on web or if capture fails (best-effort — never throws).
  Future<Uint8List?> captureScreenshotBytes() async {
    if (kIsWeb) return null;
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } on Exception catch (e) {
      Log.e('Screenshot capture failed (best-effort)', e);
      return null;
    }
  }

  /// Captures a screenshot of the widget subtree under [boundaryKey].
  ///
  /// Returns the public Storage URL on success, or null on failure
  /// (best-effort — never throws).
  Future<String?> captureScreenshot() async {
    final bytes = await captureScreenshotBytes();
    if (bytes == null) return null;
    try {
      return _storageInstance.uploadBytes(
        bytes: bytes,
        bucket: 'bug-report-attachments',
        pathPrefix: 'screenshots',
      );
    } on Exception catch (e) {
      Log.e('Screenshot upload failed (best-effort)', e);
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
      return await _storageInstance.uploadBytes(
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

  /// Collects all artifacts and submits the bug report.
  ///
  /// All boolean flags default to `true` so that callers without the new
  /// parameters retain the original behaviour unchanged.
  ///
  /// - [fileIssue]: when false, skips the Edge-Function call that creates a
  ///   GitHub issue. Use for capture-only flows (e.g. spec walk).
  /// - [uploadToSupabase]: when false, skips screenshot/dump upload to
  ///   Supabase Storage.
  /// - [artifactDir]: when non-null, saves `screenshot.png` and `dump.json`
  ///   to the given absolute device path so a worker can `adb pull` them.
  /// - [includeDump]: when false, skips layout dump capture entirely.
  Future<void> submitReport({
    required String title,
    required String description,
    String? scenarioId,
    String? sessionId,
    bool fileIssue = true,
    bool uploadToSupabase = true,
    String? artifactDir,
    bool includeDump = true,
  }) async {
    final screenshotBytes = await captureScreenshotBytes();

    String? screenshotUrl;
    String? layoutDumpJson;
    String? layoutDumpUrl;
    Map<String, dynamic>? environment;

    if (includeDump) {
      layoutDumpJson = await captureLayoutDumpJson();
    }

    if (uploadToSupabase) {
      // Collect environment only when we will use it (fileIssue needs it for
      // the Edge Function payload; upload-only flows don't need env info).
      final results = await Future.wait([
        _uploadScreenshot(screenshotBytes),
        fileIssue ? _collectEnv() : Future<Object?>.value(null),
        _uploadLayoutDump(layoutDumpJson),
      ]);
      screenshotUrl = results[0] as String?;
      environment = results[1] as Map<String, dynamic>?;
      layoutDumpUrl = results[2] as String?;
    } else if (fileIssue) {
      environment = await _collectEnv();
    }

    if (artifactDir != null && !kIsWeb) {
      await _saveToArtifactDir(
        artifactDir: artifactDir,
        screenshotBytes: screenshotBytes,
        layoutDumpJson: layoutDumpJson,
      );
    }

    if (fileIssue) {
      final effectiveTitle = (scenarioId != null || sessionId != null)
          ? '[QA] $title'
          : title;
      final effectiveDescription = _buildDescription(
        description,
        scenarioId,
        sessionId,
      );
      final logs = Log.export();

      await _repoInstance.reportBug(
        title: effectiveTitle,
        description: effectiveDescription,
        logs: logs,
        screenshotUrl: screenshotUrl,
        environment: environment,
        platform: defaultTargetPlatform.name,
        layoutDumpUrl: layoutDumpUrl,
      );
    }
  }

  Future<String?> _uploadScreenshot(Uint8List? bytes) async {
    if (bytes == null) return null;
    try {
      return await _storageInstance.uploadBytes(
        bytes: bytes,
        bucket: 'bug-report-attachments',
        pathPrefix: 'screenshots',
      );
    } on Exception catch (e) {
      Log.e('Screenshot upload failed (best-effort)', e);
      return null;
    }
  }

  Future<String?> _uploadLayoutDump(String? json) async {
    if (json == null) return null;
    try {
      return await _storageInstance.uploadBytes(
        bytes: Uint8List.fromList(utf8.encode(json)),
        bucket: 'bug-report-attachments',
        pathPrefix: 'layout-dumps',
        contentType: 'text/plain',
        extension: '.txt',
      );
    } on Exception catch (e) {
      Log.e('Layout dump upload failed (best-effort)', e);
      return null;
    }
  }

  Future<void> _saveToArtifactDir({
    required String artifactDir,
    Uint8List? screenshotBytes,
    String? layoutDumpJson,
  }) async {
    try {
      Directory(artifactDir).createSync(recursive: true);
      if (screenshotBytes != null) {
        File('$artifactDir/screenshot.png').writeAsBytesSync(screenshotBytes);
      }
      if (layoutDumpJson != null) {
        File('$artifactDir/dump.json').writeAsStringSync(layoutDumpJson);
      }
      Log.i('[BugReportCollector] Saved artifacts to $artifactDir');
    } on Exception catch (e, st) {
      Log.e(
        '[BugReportCollector] Failed to save artifacts to $artifactDir',
        e,
        st,
      );
    }
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
