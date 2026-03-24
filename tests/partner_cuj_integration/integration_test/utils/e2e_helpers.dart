import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'e2e_config.dart';

/// Initializes the E2E test environment for partner tests.
Future<ProviderContainer> initializeE2E() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  E2eConfig.validate();

  await Supabase.initialize(
    url: E2eConfig.supabaseUrl,
    anonKey: E2eConfig.supabasePublishableKey,
  );

  return ProviderContainer();
}

/// Finds a scheduled event with ticket, partner, and owner info.
///
/// Fix #410: queries multiple events and picks the first one whose partner
/// has an owner in partner_member_permissions (dev data may be incomplete).
Future<ScheduledEventContext> findScheduledEvent(
  SupabaseClient client,
) async {
  final events = await client
      .from('events')
      .select(
        '*, tickets(*), party:parties(*, partner:partners(*))',
      )
      .eq('status', 'scheduled')
      .limit(10) as List;

  if (events.isEmpty) {
    throw StateError(
      'No scheduled events found in dev database.',
    );
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
      partyId: party['id'] as String,
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
    required this.partyId,
    required this.ownerId,
  });

  final String eventId;
  final String ticketId;
  final String partnerId;
  final String partyId;
  final String ownerId;
}

/// Retries an async operation with exponential backoff.
Future<T> retry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } on Object catch (e) {
      if (attempt == maxAttempts) rethrow;
      final delay = Duration(seconds: 1 << (attempt - 1));
      Log.w(
        '⚠️ Attempt $attempt/$maxAttempts failed: $e — '
        'retrying in ${delay.inSeconds}s...',
      );
      await Future<void>.delayed(delay);
    }
  }
  throw StateError('retry: unreachable');
}
