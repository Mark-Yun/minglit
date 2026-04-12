import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show RepaintBoundary;
import 'package:minglit_kit/src/data/services/bug_report_collector.dart';
import 'package:minglit_kit/src/utils/log.dart';

/// Listens on the native MethodChannel `com.minglit.dev/qa_bug_report` and
/// triggers a programmatic bug report when the Android `QaBugReportReceiver`
/// broadcasts `com.minglit.dev.QA_BUG_REPORT`.
///
/// Only active on Android — the channel is a no-op on other platforms.
/// Intended for dev flavor only; the native receiver is registered only in
/// the dev flavor manifest.
class QaBugReportChannel {
  QaBugReportChannel._();

  static const _channel = MethodChannel('com.minglit.dev/qa_bug_report');

  /// Initialises the MethodChannel handler.
  ///
  /// Call once from `BugReporterWrapper.initState` when `enabled` is true
  /// and the platform is Android.
  ///
  /// [collector] must be bound to the [RepaintBoundary] key of the wrapped
  /// widget tree so screenshots capture the correct content.
  static void initialize(BugReportCollector collector) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'triggerBugReport') return;

      final args = call.arguments as Map<Object?, Object?>;
      final title = (args['title'] as String?) ?? 'QA Bug Report';
      final description = (args['description'] as String?) ?? '';
      final scenarioId = _nonEmptyString(args['scenario_id'] as String?);
      final sessionId = _nonEmptyString(args['session_id'] as String?);

      Log.i(
        'QaBugReportChannel: received triggerBugReport '
        'title="$title" scenario=$scenarioId session=$sessionId',
      );

      try {
        await collector.submitReport(
          title: title,
          description: description,
          scenarioId: scenarioId,
          sessionId: sessionId,
        );
        Log.i('QaBugReportChannel: report submitted successfully');
      } on Exception catch (e, st) {
        Log.e('QaBugReportChannel: report submission failed', e, st);
      }
    });
  }

  /// Releases the MethodChannel handler.
  ///
  /// Call from `BugReporterWrapper.dispose` when `enabled` is true to prevent
  /// stale handler references after the widget is removed from the tree.
  static void dispose() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _channel.setMethodCallHandler(null);
  }

  /// Returns [value] unchanged unless it is empty, in which case null is
  /// returned. Android broadcasts missing optional IDs as empty strings;
  /// normalising here keeps downstream consumers free of empty-string checks.
  static String? _nonEmptyString(String? value) =>
      (value == null || value.isEmpty) ? null : value;
}
