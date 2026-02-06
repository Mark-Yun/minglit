import 'dart:math';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:minglit_kit/minglit_core.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../utils/test_config.dart';
import '../utils/test_helpers.dart';

void main() {
  const testBucket = 'verification-proofs';

  // 1. Admin Client (RLS Bypass)
  final adminClient = SupabaseClient(
    TestConfig.supabaseUrl,
    TestConfig.serviceRoleKey,
    headers: {
      'Authorization': 'Bearer ${TestConfig.serviceRoleKey}',
      'apikey': TestConfig.serviceRoleKey,
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
    final token = jwt.sign(SecretKey(TestConfig.jwtSecret));

    return SupabaseClient(
      TestConfig.supabaseUrl,
      TestConfig.serviceRoleKey,
      headers: {
        'Authorization': 'Bearer $token',
        'apikey': TestConfig.serviceRoleKey,
      },
    );
  }

  late String testUserId;
  late String testPartnerId;
  late String testPartnerOwnerId;
  late String testEventId;
  late String testTicketId;
  late String testVerificationId;

  // Shared Clients
  late SupabaseClient userClient;

  setUpAll(() async {
    Log.i('🚀 [Setup] Fetching seeded data for storage tests...');

    // 1. Find a Normal User via Helper
    testUserId = await getMale25VerifiedUserId(adminClient);

    // 2. Find a Scheduled Event via Helper
    final eventCtx = await findScheduledEvent(adminClient);
    testEventId = eventCtx.eventId;
    testTicketId = eventCtx.ticketId;
    testPartnerId = eventCtx.partnerId;
    testPartnerOwnerId = eventCtx.ownerId;

    // 3. Find a Verification ID
    testVerificationId = await getCareerVerificationId(adminClient);

    // 4. Initialize Clients
    userClient = createUserClient(testUserId);

    Log.i(
      '✅ [Setup] User: $testUserId, Partner: $testPartnerId, Owner: $testPartnerOwnerId',
    );
  });

  group('Infrastructure: Secure File Management System', () {
    test('SC1: File metadata (minglit_files) is auto-created on upload',
        () async {
      final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.txt';
      final path = '$testUserId/applications/$testEventId/$fileName';
      final fileData = Uint8List.fromList('Test Content'.codeUnits);

      Log.i('📤 [Test] Uploading file to $path...');
      await userClient.storage.from(testBucket).uploadBinary(path, fileData);

      // Wait for trigger
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Verify: minglit_files entry exists
      final metadata = await adminClient
          .from('minglit_files')
          .select()
          .eq('file_path', path)
          .eq('bucket_id', testBucket)
          .maybeSingle();

      expect(
        metadata,
        isNotNull,
        reason: 'minglit_files record should be created by trigger',
      );
      expect(metadata!['owner_id'], testUserId);
      Log.i('✅ [Test] Metadata verified.');
    });

    test(
        'SC2: Access Grant is auto-created on Application and RLS allows access',
        () async {
      final userClient = createUserClient(testUserId);
      final partnerClient = createUserClient(testPartnerOwnerId);

      // Cleanup: Ensure no existing application for this user/event pair
      await adminClient
          .from('event_applications')
          .delete()
          .eq('event_id', testEventId)
          .eq('user_id', testUserId);

      final fileName =
          'grant_test_${DateTime.now().millisecondsSinceEpoch}.txt';
      final path = '$testUserId/applications/$testEventId/$fileName';

      // 1. User Uploads File
      await userClient.storage.from(testBucket).uploadBinary(
            path,
            Uint8List.fromList('Grant Test Content'.codeUnits),
          );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 2. User Submits Application
      Log.i('📝 [Test] Submitting application to trigger grant...');
      await adminClient.rpc<dynamic>(
        'apply_event',
        params: {
          'p_event_id': testEventId,
          'p_ticket_id': testTicketId,
          'p_user_id': testUserId,
          'p_payment_id': 'PAY_MOCK_${Random().nextInt(1000)}',
          'p_payment_amount': 1000,
          'p_verification_data': {
            'partner_id': testPartnerId,
            'verification_id': testVerificationId,
            'data': {'proof': path},
          },
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 3. Verify: Grant exists in DB
      final fileRecord = await adminClient
          .from('minglit_files')
          .select('id')
          .eq('file_path', path)
          .single();
      final fileId = fileRecord['id'];

      final grant = await adminClient
          .from('file_access_grants')
          .select()
          .eq('file_id', fileId as Object)
          .eq('viewer_id', testPartnerOwnerId as Object)
          .maybeSingle();

      expect(
        grant,
        isNotNull,
        reason: 'Grant should be created for partner owner',
      );
      Log.i('✅ [Test] Grant record verified in DB.');

      // 4. Verify: Partner can actually READ the file via Storage API (RLS Check)
      Log.i('🔍 [Test] Partner trying to read file via Storage API...');
      try {
        final downloaded =
            await partnerClient.storage.from(testBucket).download(path);
        expect(downloaded, isNotNull);
        Log.i('✅ [Test] RLS allowed partner access.');
      } catch (e) {
        fail('Partner should have access but failed: $e');
      }

      // 5. Verify: Other user is BLOCKED (RLS Check)
      const otherUserId =
          '00000000-0000-0000-0000-000000000000'; // Non-existent or dummy
      final otherClient = createUserClient(otherUserId);
      Log.i('🚫 [Test] Other user trying to read file...');

      expect(
        () => otherClient.storage.from(testBucket).download(path),
        throwsA(isA<StorageException>()),
        reason: 'Random user should be blocked by RLS',
      );
      Log.i('✅ [Test] RLS blocked unauthorized access.');
    });

    test('SC3: Event Reschedule updates Grant Expiration', () async {
      // Note: Relies on SC2 having created a grant.
      // Fetch the grant created in SC2
      final grantRes = await adminClient
          .from('file_access_grants')
          .select('*, file:minglit_files!inner(file_path)')
          .eq('viewer_id', testPartnerOwnerId)
          .like('file.file_path', '%/applications/$testEventId/%')
          .limit(1)
          .maybeSingle();

      if (grantRes == null) {
        Log.w('⚠️ SC3 Skipped: No grant found from SC2.');
        return;
      }

      final grantId = grantRes['id'];
      final initialExpires = DateTime.parse(grantRes['expires_at'] as String);
      Log.i('📅 [Test] Initial Expires: $initialExpires');

      // 1. Reschedule Event (Add 7 days)
      Log.i('📅 [Test] Rescheduling event (adding 7 days)...');
      final eventRes = await adminClient
          .from('events')
          .select('end_time')
          .eq('id', testEventId)
          .single();
      final currentEnd = DateTime.parse(eventRes['end_time'] as String);
      final newEnd = currentEnd.add(const Duration(days: 7));

      await adminClient
          .from('events')
          .update({'end_time': newEnd.toIso8601String()}).eq('id', testEventId);

      // Wait for trigger
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 2. Verify Grant Expiration Updated
      final updatedGrant = await adminClient
          .from('file_access_grants')
          .select('expires_at')
          .eq('id', grantId as Object)
          .single();

      final updatedExpires =
          DateTime.parse(updatedGrant['expires_at'] as String);
      Log.i('📅 [Test] Updated Expires: $updatedExpires');

      // Check if updated (should be roughly initial + 7 days)
      final diff = updatedExpires.difference(initialExpires).inDays;
      expect(
        diff,
        closeTo(7, 1),
        reason: 'Expiration should be extended by ~7 days',
      );

      Log.i('✅ [Test] Grant expiration updated successfully.');
    });
  });
}
