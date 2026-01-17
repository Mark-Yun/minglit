import 'dart:math';

import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

// --- CONFIGURATION ---
const supabaseUrl = 'http://127.0.0.1:54321';
// Actual Local Service Role Key
const serviceRoleKey = 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz';
const jwtSecret = 'super-secret-jwt-token-with-at-least-32-characters-long';

void main() {
  // 1. Admin Client (RLS Bypass for Setup/Query)
  final adminClient = SupabaseClient(
    supabaseUrl,
    serviceRoleKey,
    headers: {
      'Authorization': 'Bearer $serviceRoleKey',
      'apikey': serviceRoleKey,
    },
  );

  // Helper: Create a Client acting as a specific user (Fake JWT Factory)
  SupabaseClient createUserClient(String userId) {
    final jwt = JWT(
      {
        'sub': userId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'test_user@example.com',
      },
    );
    final token = jwt.sign(SecretKey(jwtSecret));

    return SupabaseClient(
      supabaseUrl,
      serviceRoleKey,
      headers: {
        'Authorization': 'Bearer $token',
        'apikey': serviceRoleKey,
      },
    );
  }

  // Test Data IDs (Fetched from Seeder)
  late String testUserId;
  late String testPartnerId;
  late String testVerificationId;
  late String testEventId;
  late String testTicketId;

  setUpAll(() async {
    print('🚀 [Setup] Fetching seeded data...');

    // 1. Fetch a Normal User (user_1)
    final userRes = await adminClient.from('user_profiles').select().eq('username', 'user_1').maybeSingle();
    
    if (userRes == null) {
      throw Exception('🚨 User user_1 not found! Did you run the seeder?');
    }
    testUserId = userRes['id'];
    print('👤 [Setup] Using User: $testUserId');

    // 2. Fetch an Event and Ticket
    final eventRes = await adminClient
        .from('events')
        .select('*, tickets(*), party:parties(*)')
        .eq('status', 'scheduled')
        .limit(1)
        .maybeSingle();

    if (eventRes == null) {
      throw Exception('🚨 No scheduled events found!');
    }
    testEventId = eventRes['id'];
    final party = eventRes['party'] as Map<String, dynamic>;
    testPartnerId = party['partner_id'];
    
    final tickets = eventRes['tickets'] as List;
    if (tickets.isEmpty) {
      throw Exception('🚨 Event has no tickets!');
    }
    testTicketId = tickets[0]['id'];
    print('🎫 [Setup] Using Event: $testEventId, Ticket: $testTicketId');

    // 3. Fetch a Verification
    final verifRes = await adminClient
        .from('verifications')
        .select()
        .eq('category', 'career')
        .limit(1)
        .maybeSingle();
    
    testVerificationId = verifRes?['id'] ?? (await adminClient.from('verifications').select().limit(1).single())['id'];
    print('✅ [Setup] Using Verification: $testVerificationId');
  });

  test('One-Shot Application Flow Test (Apply -> Pending -> Approve -> Confirmed)', () async {
    final userClient = createUserClient(testUserId);
    final eventRepo = EventRepository(supabase: userClient);

    print('📝 [Test] Starting One-Shot Application...');

    // 1. Apply Event (Atomic RPC Call)
    final appId = await eventRepo.applyEvent(
      eventId: testEventId,
      ticketId: testTicketId,
      userId: testUserId,
      paymentId: 'PAY_${Random().nextInt(9999)}',
      paymentAmount: 1000,
      verificationData: {
        'partner_id': testPartnerId,
        'verification_id': testVerificationId,
        'data': {'company': 'Google', 'position': 'Dev'},
      },
    );

    expect(appId, isNotNull);
    print('✅ [Test] Applied successfully. AppID: $appId');

    // 2. Verify Status
    final app = await userClient.from('event_applications').select().eq('id', appId).single();
    expect(app['status'], equals('pending_review'));

    // 3. Partner Approval (via Admin Client)
    print('👮 [Test] Admin approving verification...');
    await adminClient
        .from('verification_submissions')
        .update({'status': 'approved'})
        .eq('application_id', appId);

    // 4. Final Verification (Trigger Check)
    await Future.delayed(const Duration(milliseconds: 500));
    
    final updatedApp = await adminClient.from('event_applications').select().eq('id', appId).single();
    expect(updatedApp['status'], equals('approved'));

    final participant = await adminClient.from('event_participants').select().eq('application_id', appId).maybeSingle();
    expect(participant, isNotNull);
    expect(participant!['ticket_code'], isNotNull);

    print('🎉 [Test] ONE-SHOT FLOW VERIFIED!');
  });
}