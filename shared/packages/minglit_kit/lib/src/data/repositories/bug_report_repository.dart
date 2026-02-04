import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/log.dart';

class BugReportRepository {
  final SupabaseClient _supabase;

  BugReportRepository(this._supabase);

  Future<void> reportBug({
    required String title,
    required String description,
    required String logs,
  }) async {
    try {
      await _supabase.functions.invoke(
        'report-bug',
        body: {
          'title': title,
          'description': description,
          'logs': logs,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      Log.i('Bug reported successfully via Edge Function');
    } catch (e, st) {
      Log.e('Failed to report bug', e, st);
      throw Exception('Failed to report bug: $e');
    }
  }
}
