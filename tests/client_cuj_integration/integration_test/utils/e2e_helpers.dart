import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'e2e_config.dart';

/// Initializes the E2E test environment.
///
/// 1. Binds the integration test framework
/// 2. Validates env config
/// 3. Initializes Supabase connection to dev server
/// 4. Returns a [ProviderContainer] for accessing Riverpod providers
Future<ProviderContainer> initializeE2E() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  E2eConfig.validate();

  await Supabase.initialize(
    url: E2eConfig.supabaseUrl,
    anonKey: E2eConfig.supabasePublishableKey,
  );

  return ProviderContainer();
}

/// Finds a scheduled event with its ticket, partner, and owner info.
// Fix #410: iterate candidates to find one with a valid partner owner
Future<ScheduledEventContext> findScheduledEvent(
  SupabaseClient client,
) async {
  final events = await client
      .from('events')
      .select('*, tickets(*), party:parties(*, partner:partners(*))')
      .eq('status', 'scheduled')
      .order('created_at', ascending: false)
      .limit(10) as List;

  if (events.isEmpty) {
    throw StateError('No scheduled events found in dev database.');
  }

  for (final eventRes in events) {
    final event = eventRes as Map<String, dynamic>;
    final eventId = event['id'] as String;
    final tickets = event['tickets'] as List;
    if (tickets.isEmpty) continue;

    final party = event['party'] as Map<String, dynamic>?;
    if (party == null) continue;
    final partner = party['partner'] as Map<String, dynamic>?;
    if (partner == null) continue;
    final partnerId = partner['id'] as String;

    final ownerRes = await client
        .from('partner_member_permissions')
        .select('user_id')
        .eq('partner_id', partnerId)
        .eq('role', 'owner')
        .maybeSingle();
    if (ownerRes == null) continue;

    final ticketId =
        (tickets.first as Map<String, dynamic>)['id'] as String;
    return ScheduledEventContext(
      eventId: eventId,
      ticketId: ticketId,
      partnerId: partnerId,
      ownerId: ownerRes['user_id'] as String,
    );
  }

  throw StateError(
    'No scheduled event with tickets and a partner owner found '
    'in dev database.',
  );
}

/// Context record for a scheduled event.
class ScheduledEventContext {
  const ScheduledEventContext({
    required this.eventId,
    required this.ticketId,
    required this.partnerId,
    required this.ownerId,
  });

  final String eventId;
  final String ticketId;
  final String partnerId;
  final String ownerId;
}

/// Retries an async operation with exponential backoff.
///
/// Useful for network flakiness mitigation in CI.
Future<T> retry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
      Log.w(
        '⚠️ Attempt $attempt/$maxAttempts failed: $e — '
        'retrying in ${delay.inSeconds}s...',
      );
      await Future<void>.delayed(delay);
    }
  }
  // Unreachable, but Dart needs it.
  throw StateError('retry: unreachable');
}

/// Gets a verification ID for test applications.
Future<String> getCareerVerificationId(SupabaseClient client) async {
  final res = await client
      .from('verifications')
      .select('id')
      .eq('category', 'career')
      .limit(1)
      .maybeSingle();

  if (res == null) {
    final any =
        await client.from('verifications').select('id').limit(1).single();
    return any['id'] as String;
  }
  return res['id'] as String;
}
