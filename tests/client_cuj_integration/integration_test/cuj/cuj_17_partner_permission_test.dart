import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 17: Partner Permission Branching
/// — owner can view settlements, manager cannot,
/// staff can only view submissions.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String ownerEmail;
  late String managerUserId;
  late String managerEmail;
  late String staffUserId;
  late String staffEmail;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    eventCtx = await findScheduledEvent(adminClient);

    ownerEmail = await getPartnerOwnerEmail(
      adminClient,
      ownerId: eventCtx.ownerId,
    );

    // Use male test user as temporary manager
    managerEmail = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(managerEmail);
    managerUserId = Supabase.instance.client.auth.currentUser!.id;
    await signOut();

    // Use female test user as temporary staff
    staffEmail = await getTestUserEmail(adminClient, gender: 'female');
    await signInAsTestUser(staffEmail);
    staffUserId = Supabase.instance.client.auth.currentUser!.id;
    await signOut();

    // Add manager and staff roles (cleanup first)
    await _cleanupRoles(adminClient, eventCtx.partnerId, managerUserId);
    await _cleanupRoles(adminClient, eventCtx.partnerId, staffUserId);

    await adminClient.from('partner_member_permissions').insert({
      'partner_id': eventCtx.partnerId,
      'user_id': managerUserId,
      'role': 'manager',
    });

    await adminClient.from('partner_member_permissions').insert({
      'partner_id': eventCtx.partnerId,
      'user_id': staffUserId,
      'role': 'staff',
    });

    // Ensure a settlement exists for this partner (create via completed event)
    await _ensureSettlementExists(adminClient, eventCtx);
  });

  tearDownAll(() async {
    // Remove temporary role assignments
    await _cleanupRoles(adminClient, eventCtx.partnerId, managerUserId);
    await _cleanupRoles(adminClient, eventCtx.partnerId, staffUserId);
    await signOut();
  });

  group('CUJ 17: Partner Permission Branching', () {
    testWidgets('owner는 settlement을 조회할 수 있다', (tester) async {
      await signInAsTestUser(ownerEmail);
      final client = Supabase.instance.client;

      final settlements = await client
          .from('settlements')
          .select()
          .eq('partner_id', eventCtx.partnerId);

      expect(
        settlements,
        isNotEmpty,
        reason: 'Owner (SETTLEMENT_VIEW) should see settlements',
      );

      await signOut();
    });

    testWidgets('manager는 settlement을 조회할 수 없다 (RLS 차단)', (tester) async {
      await signInAsTestUser(managerEmail);
      final client = Supabase.instance.client;

      // Manager lacks SETTLEMENT_VIEW permission
      final settlements = await client
          .from('settlements')
          .select()
          .eq('partner_id', eventCtx.partnerId);

      expect(
        settlements,
        isEmpty,
        reason: 'Manager (no SETTLEMENT_VIEW) should not see settlements',
      );

      await signOut();
    });

    testWidgets('staff는 verification_submissions만 접근 가능하다', (tester) async {
      await signInAsTestUser(staffEmail);
      final client = Supabase.instance.client;

      // Staff has VERIFY_LIST_VIEW — can see submissions for their partner
      final submissions = await client
          .from('verification_submissions')
          .select()
          .eq('partner_id', eventCtx.partnerId);

      // Staff should be able to query (may be empty if no submissions exist,
      // but the query itself should not fail)
      expect(submissions, isA<List<dynamic>>());

      // Staff should NOT see settlements
      final settlements = await client
          .from('settlements')
          .select()
          .eq('partner_id', eventCtx.partnerId);

      expect(
        settlements,
        isEmpty,
        reason: 'Staff (no SETTLEMENT_VIEW) should not see settlements',
      );

      await signOut();
    });
  });
}

/// Ensures at least one settlement exists for the partner.
Future<void> _ensureSettlementExists(
  SupabaseClient admin,
  ScheduledEventContext ctx,
) async {
  final existing = await admin
      .from('settlements')
      .select('id')
      .eq('partner_id', ctx.partnerId)
      .maybeSingle();

  if (existing != null) return;

  // Create a minimal settlement record for testing
  await admin.from('settlements').insert({
    'event_id': ctx.eventId,
    'partner_id': ctx.partnerId,
    'status': 'pending',
    'total_sales': 0,
    'total_refunds': 0,
    'pg_fee': 0,
    'platform_fee': 0,
    'net_amount': 0,
  });
}

Future<void> _cleanupRoles(
  SupabaseClient admin,
  String partnerId,
  String userId,
) async {
  try {
    await admin
        .from('partner_member_permissions')
        .delete()
        .eq('partner_id', partnerId)
        .eq('user_id', userId);
  } on Object catch (_) {}
}
