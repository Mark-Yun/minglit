import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../utils/test_config.dart';

void main() {
  final adminClient = SupabaseClient(
    TestConfig.supabaseUrl,
    TestConfig.serviceRoleKey,
    headers: {
      'Authorization': 'Bearer ${TestConfig.serviceRoleKey}',
      'apikey': TestConfig.serviceRoleKey,
    },
  );

  group('Event Application Fetch Tests', () {
    test('Should fetch applications with correct structure', () async {
      // 1. Get any event id
      final events = await adminClient.from('events').select('id').limit(1);
      if (events.isEmpty) {
        print('No events found, skipping test');
        return;
      }
      final eventId = events.first['id'] as String;

      // 1.5 Create a dummy application if needed (or assume seed data)
      // Let's create one to be sure
      final userId = (await adminClient
          .from('user_profiles')
          .select('id')
          .limit(1)
          .single())['id'];
      try {
        await adminClient.from('event_applications').insert({
          'event_id': eventId,
          'user_id': userId,
          'ticket_id': (await adminClient
              .from('tickets')
              .select('id')
              .eq('event_id', eventId)
              .limit(1)
              .single())['id'],
          'payment_id': 'dummy_payment',
          'payment_amount': 1000,
          'status': 'pending_review',
        });
      } catch (e) {
        // Ignore duplicate key error if already exists
      }

      // 2. Fetch applications using raw query (simulating Repo)
      final data = await adminClient
          .from('event_applications')
          .select(
            '*, user:user_profiles(*), submission:verification_submissions(*)',
          )
          .eq('event_id', eventId);

      print('Data type: ${data.runtimeType}');
      if (data.isNotEmpty) {
        final firstItem = data.first;
        print('First item type: ${firstItem.runtimeType}');
        print('User field type: ${firstItem['user']?.runtimeType}');

        // Assertions
        expect(firstItem, isA<Map<String, dynamic>>());

        // If user is List, that's the bug!
        if (firstItem['user'] is List) {
          fail('BUG DETECTED: "user" field is a List, expected Map (Object).');
        }
      }
    });
  });
}
