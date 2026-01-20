import 'dart:math';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../utils/test_config.dart';

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
  late SupabaseClient partnerClient;

  setUpAll(() async {
    print('🚀 [Setup] Fetching seeded data for storage tests...');

    // 1. Find a Normal User (25yo, Male, Verified) by attributes
    final targetBirthYear = DateTime.now().year - 25 + 1;
    final userRes = await adminClient
        .from('user_profiles')
        .select()
        .eq('gender', 'male')
        .eq('birth_date', '$targetBirthYear-01-01')
        .like('username', '%_ok')
        .limit(1)
        .single();
    testUserId = userRes['id'];

    // 2. Find a Scheduled Event with its Partner Owner
    final eventRes = await adminClient
        .from('events')
        .select('*, tickets(*), party:parties(*, partner:partners(*))')
        .eq('status', 'scheduled')
        .limit(1)
        .single();
    
    testEventId = eventRes['id'];
    testTicketId = (eventRes['tickets'] as List)[0]['id'];
    
    final party = eventRes['party'] as Map<String, dynamic>;
    final partner = party['partner'] as Map<String, dynamic>;
    testPartnerId = partner['id'];

    // Find Partner Owner
    final ownerRes = await adminClient
        .from('partner_member_permissions')
        .select('user_id')
        .eq('partner_id', testPartnerId)
        .eq('role', 'owner')
        .single();
    testPartnerOwnerId = ownerRes['user_id'];

    // 3. Find a Verification ID (Career)
    final verifRes = await adminClient
        .from('verifications')
        .select('id')
        .eq('category', 'career')
        .limit(1)
        .single();
    testVerificationId = verifRes['id'];

    // 4. Initialize Clients
    userClient = createUserClient(testUserId);
    partnerClient = createUserClient(testPartnerOwnerId);

    print(
        '✅ [Setup] User: $testUserId, Partner: $testPartnerId, Owner: $testPartnerOwnerId');
  });

  group('Infrastructure: Secure File Management System', () {
    test('SC1: File metadata (minglit_files) is auto-created on upload',
        () async {
      final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.txt';
      final path = '$testUserId/applications/$testEventId/$fileName';
      final fileData = Uint8List.fromList('Test Content'.codeUnits);

      print('📤 [Test] Uploading file to $path...');
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

      expect(metadata, isNotNull,
          reason: 'minglit_files record should be created by trigger');
      expect(metadata!['owner_id'], testUserId);
      print('✅ [Test] Metadata verified.');
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
      print('📝 [Test] Submitting application to trigger grant...');
      await adminClient.rpc('apply_event', params: {
        'p_event_id': testEventId,
        'p_ticket_id': testTicketId,
        'p_user_id': testUserId,
        'p_payment_id': 'PAY_MOCK_${Random().nextInt(1000)}',
        'p_payment_amount': 1000,
        'p_verification_data': {
          'partner_id': testPartnerId,
          'verification_id': testVerificationId,
          'data': {'proof': path}
        },
      });

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
          .eq('file_id', fileId)
          .eq('viewer_id', testPartnerOwnerId)
          .maybeSingle();

      expect(grant, isNotNull,
          reason: 'Grant should be created for partner owner');
      print('✅ [Test] Grant record verified in DB.');

      // 4. Verify: Partner can actually READ the file via Storage API (RLS Check)
      print('🔍 [Test] Partner trying to read file via Storage API...');
      try {
        final downloaded =
            await partnerClient.storage.from(testBucket).download(path);
        expect(downloaded, isNotNull);
        print('✅ [Test] RLS allowed partner access.');
      } catch (e) {
        fail('Partner should have access but failed: $e');
      }

      // 5. Verify: Other user is BLOCKED (RLS Check)
      final otherUserId =
          '00000000-0000-0000-0000-000000000000'; // Non-existent or dummy
      final otherClient = createUserClient(otherUserId);
      print('🚫 [Test] Other user trying to read file...');

      expect(
        () => otherClient.storage.from(testBucket).download(path),
        throwsA(isA<StorageException>()),
        reason: 'Random user should be blocked by RLS',
      );
      print('✅ [Test] RLS blocked unauthorized access.');
    });
  });
}