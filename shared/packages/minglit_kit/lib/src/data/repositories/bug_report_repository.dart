import 'package:minglit_kit/src/utils/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for reporting client-side bugs.
class BugReportRepository {
  /// Creates a [BugReportRepository] with a Supabase client.
  BugReportRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Sends a bug report to the backend.
  Future<void> reportBug({
    required String title,
    required String description,
    required String logs,
    String? screenshotUrl,
    Map<String, dynamic>? environment,
    String? platform,
    String? layoutDumpUrl,
  }) async {
    try {
      await _supabase.functions.invoke(
        'bug-report',
        body: {
          'title': title,
          'description': description,
          'logs': logs,
          'timestamp': DateTime.now().toIso8601String(),
          ...?platform != null ? {'platform': platform} : null,
          ...?screenshotUrl != null ? {'screenshotUrl': screenshotUrl} : null,
          ...?environment != null ? {'environment': environment} : null,
          ...?layoutDumpUrl != null ? {'layoutDumpUrl': layoutDumpUrl} : null,
        },
      );
      Log.i('Bug reported successfully via Edge Function');
    } catch (e, st) {
      Log.e('Failed to report bug', e, st);
      throw Exception('Failed to report bug: $e');
    }
  }
}
