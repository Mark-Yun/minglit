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

  late String partnerId;
  late String partyId;
  late String eventId;

  setUpAll(() async {
    // Ensure DB is seeded and get a partner
    partnerId = await ensureDatabaseSeeded(adminClient);
  });

  group('Capacity Synchronization', () {
    test('1. Party max_participants should sync with ticket templates', () async {
      // 1. Create Party (Initially max=0)
      final partyRes = await adminClient
          .from('parties')
          .insert({
            'partner_id': partnerId,
            'title': 'Capacity Test Party',
            'min_confirmed_count': 0,
            'max_participants': 0,
          })
          .select()
          .single();
      partyId = partyRes['id'];
      expect(partyRes['max_participants'], 0);

      // 2. Add Ticket Template (Qty: 10)
      await adminClient.from('ticket_templates').insert({
        'party_id': partyId,
        'name': 'Early Bird',
        'quantity': 10,
        'price': 10000,
      });

      // 3. Verify Party Updated
      final partyUpdated = await adminClient
          .from('parties')
          .select('max_participants')
          .eq('id', partyId)
          .single();
      expect(partyUpdated['max_participants'], 10);

      // 4. Add Another Template (Qty: 20)
      await adminClient.from('ticket_templates').insert({
        'party_id': partyId,
        'name': 'Regular',
        'quantity': 20,
        'price': 20000,
      });

      // 5. Verify Sum (10 + 20 = 30)
      final partyFinal = await adminClient
          .from('parties')
          .select('max_participants')
          .eq('id', partyId)
          .single();
      expect(partyFinal['max_participants'], 30);
    });

    test('2. Event max_participants should sync with tickets', () async {
      // 1. Create Event (Set max=1 initially to pass constraint check > 0)
      final eventRes = await adminClient
          .from('events')
          .insert({
            'party_id': partyId,
            'start_time': DateTime.now().toIso8601String(),
            'end_time': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
            'min_confirmed_count': 0,
            'max_participants': 1, 
          })
          .select()
          .single();
      eventId = eventRes['id'];
      expect(eventRes['max_participants'], 1);

      // 2. Add Ticket (Qty: 5)
      await adminClient.from('tickets').insert({
        'event_id': eventId,
        'name': 'Event Ticket 1',
        'quantity': 5,
        'price': 10000,
      });

      // 3. Verify Event Updated
      final eventUpdated = await adminClient
          .from('events')
          .select('max_participants')
          .eq('id', eventId)
          .single();
      expect(eventUpdated['max_participants'], 5);

      // 4. Update Ticket Quantity (5 -> 15)
      await adminClient
          .from('tickets')
          .update({'quantity': 15})
          .eq('event_id', eventId);

      // 5. Verify Event Updated
      final eventFinal = await adminClient
          .from('events')
          .select('max_participants')
          .eq('id', eventId)
          .single();
      expect(eventFinal['max_participants'], 15);
    });

    test('3. Constraint check: min_confirmed > max_participants should fail', () async {
      // Current Max is 30 for Party
      try {
        await adminClient
            .from('parties')
            .update({'min_confirmed_count': 31})
            .eq('id', partyId);
        fail('Should have thrown check constraint violation');
      } catch (e) {
        expect(e.toString(), contains('check_min_max_participants'));
      }

      // Current Max is 15 for Event
      try {
        await adminClient
            .from('events')
            .update({'min_confirmed_count': 16})
            .eq('id', eventId);
        fail('Should have thrown check constraint violation for event');
      } catch (e) {
        expect(e.toString(), contains('check_min_max_participants'));
      }
    });
  });
}