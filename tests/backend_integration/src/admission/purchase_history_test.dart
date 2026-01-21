import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../utils/test_config.dart';
import '../utils/test_helpers.dart';

void main() {
  final adminClient = SupabaseClient(
    TestConfig.supabaseUrl,
    TestConfig.serviceRoleKey,
    headers: {
      'Authorization': 'Bearer ${TestConfig.serviceRoleKey}',
      'apikey': TestConfig.serviceRoleKey,
    },
  );

  group('EventRepository (Raw): Purchase History Tests', () {
    late String testUserId;
    late String testEventId;
    late String testTicketId;

    setUpAll(() async {
      // 1. Get Test User
      testUserId = await getMale25VerifiedUserId(adminClient);

      // 2. Get Test Event
      final eventCtx = await findScheduledEvent(adminClient);
      testEventId = eventCtx.eventId;
      testTicketId = eventCtx.ticketId;

      // 3. Ensure an application exists (status: paid)
      await adminClient.from('event_applications').upsert({
        'event_id': testEventId,
        'user_id': testUserId,
        'ticket_id': testTicketId,
        'status': 'paid',
        'payment_amount': 10000,
      }, onConflict: 'event_id, user_id');
    });

    test('Query returns list with joined event and ticket data', () async {
      // Re-implementing the repository query logic directly for testing
      final data = await adminClient
          .from('event_applications')
          .select(
            '*, '
            'event:events(*, party:parties(*, location:locations(*))), '
            'ticket:tickets(*)',
          )
          .eq('user_id', testUserId)
          .order('created_at', ascending: false);

      expect(data, isNotEmpty);

      final app = data.first;
      expect(app['user_id'], testUserId);

      // Verify Joins
      expect(app['event'], isNotNull,
          reason: 'Event relation should be joined');
      final event = app['event'] as Map<String, dynamic>;
      expect(event['party'], isNotNull,
          reason: 'Party relation should be joined via Event');
      expect(app['ticket'], isNotNull,
          reason: 'Ticket relation should be joined');

      print('✅ History Count: ${data.length}');
      print('📍 First Event: ${event['title'] ?? event['party']['title']}');
    });
  });
}
