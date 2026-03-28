import 'package:postgres/postgres.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import '../utils/test_config.dart';
import '../utils/test_database.dart';
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

  group('S03: Settlement Pipeline Scenario', () {
    late Connection dbConn;
    late String testPartnerId;
    late String testPartyId;
    late String testEventId;
    late String testTicketId;
    late String testUserId;

    setUpAll(() async {
      dbConn = await TestDatabase.createConnection();
      testUserId = await getMale25VerifiedUserId(adminClient);

      // Create isolated test data
      final partnerRes = await adminClient
          .from('partners')
          .insert({'name': 'Settlement Test Partner'})
          .select()
          .single();
      testPartnerId = partnerRes['id'] as String;

      final partyRes = await adminClient
          .from('parties')
          .insert({
            'partner_id': testPartnerId,
            'title': 'Settlement Test Party',
            'min_confirmed_count': 0,
            'max_participants': 10,
          })
          .select()
          .single();
      testPartyId = partyRes['id'] as String;

      final eventRes = await adminClient
          .from('events')
          .insert({
            'party_id': testPartyId,
            'start_time': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'end_time': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'min_confirmed_count': 0,
            'max_participants': 10,
            'status': 'scheduled',
          })
          .select()
          .single();
      testEventId = eventRes['id'] as String;

      final ticketRes = await adminClient
          .from('tickets')
          .insert({
            'event_id': testEventId,
            'name': 'Settlement Ticket',
            'quantity': 10,
            'price': 100000,
          })
          .select()
          .single();
      testTicketId = ticketRes['id'] as String;
    });

    tearDownAll(() async {
      // Cleanup in reverse order
      await adminClient
          .from('settlements')
          .delete()
          .eq('event_id', testEventId);
      await adminClient
          .from('event_applications')
          .delete()
          .eq('event_id', testEventId);
      await adminClient.from('tickets').delete().eq('id', testTicketId);
      await adminClient.from('events').delete().eq('id', testEventId);
      await adminClient.from('parties').delete().eq('id', testPartyId);
      await adminClient.from('partners').delete().eq('id', testPartnerId);
      await dbConn.close();
    });

    test('Payment → event completed → settlement created with correct fees',
        () async {
      // Step 1: Create paid application (total_sales = 100000)
      await adminClient.from('event_applications').insert({
        'event_id': testEventId,
        'ticket_id': testTicketId,
        'user_id': testUserId,
        'status': 'paid',
        'payment_id': 'imp_settle_scenario_1',
        'payment_amount': 100000,
      });

      // Step 2: Complete event → triggers create_settlement_on_event_completion
      await adminClient
          .from('events')
          .update({'status': 'completed'}).eq('id', testEventId);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Step 3: Verify settlement created
      final settlements = await adminClient
          .from('settlements')
          .select()
          .eq('event_id', testEventId);

      expect(settlements, isNotEmpty, reason: 'Settlement should be created');

      final settlement = settlements.first;
      expect(settlement['total_sales'], equals(100000),
          reason: 'total_sales=100000');
      expect(settlement['pg_fee'], equals(3500), reason: 'pg_fee=3500 (3.5%)');
      expect(settlement['platform_fee'], equals(5000),
          reason: 'platform_fee=5000 (5%)');
      expect(settlement['vat'], equals(850), reason: 'vat=850 (10% of fees)');
      expect(settlement['net_amount'], equals(90650),
          reason: 'net_amount=90650');
      expect(settlement['status'], equals('pending'),
          reason: 'Initial status=pending');
    });

    test(
        'update_settlement_ready_status() transitions pending → ready after 7 days',
        () async {
      // Manually set event_date to 8 days ago to simulate 7-day hold period
      await dbConn.execute(
        "UPDATE public.settlements SET event_date = now() - interval '8 days' WHERE event_id = '${testEventId}'",
      );

      // Call cron function directly
      await adminClient.rpc<dynamic>('update_settlement_ready_status');

      final settlements = await adminClient
          .from('settlements')
          .select()
          .eq('event_id', testEventId);

      expect(settlements.first['status'], equals('ready'),
          reason: 'After 7 days, status should transition to ready');
    });
  });
}
