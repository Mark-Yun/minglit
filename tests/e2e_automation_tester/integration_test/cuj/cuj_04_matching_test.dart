import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 04: Matching — Cast mutual votes and verify match creation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late String maleUserId;
  late String femaleUserId;
  late String eventId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    // Resolve test users
    final maleEmail = await getTestUserEmail(adminClient, gender: 'male');
    final femaleEmail = await getTestUserEmail(adminClient, gender: 'female');

    // Get user IDs via admin
    await signInAsTestUser(maleEmail);
    maleUserId = Supabase.instance.client.auth.currentUser!.id;
    await signOut();

    await signInAsTestUser(femaleEmail);
    femaleUserId = Supabase.instance.client.auth.currentUser!.id;
    await signOut();

    // Get a scheduled event
    final ctx = await findScheduledEvent(adminClient);
    eventId = ctx.eventId;
  });

  tearDownAll(() async {
    // Cleanup votes and matches
    try {
      await adminClient
          .from('match_votes')
          .delete()
          .eq('event_id', eventId)
          .inFilter('voter_id', [maleUserId, femaleUserId]);
    } on Object catch (_) {}
    try {
      await adminClient
          .from('event_matches')
          .delete()
          .eq('event_id', eventId)
          .or('user_a_id.eq.$maleUserId,user_b_id.eq.$maleUserId');
    } on Object catch (_) {}
    await signOut();
  });

  group('CUJ 04: Matching', () {
    testWidgets('Should cast mutual votes and verify match data',
        (tester) async {
      // 1. Cleanup existing votes (idempotent)
      try {
        await adminClient
            .from('match_votes')
            .delete()
            .eq('event_id', eventId)
            .inFilter('voter_id', [maleUserId, femaleUserId]);
        await adminClient
            .from('event_matches')
            .delete()
            .eq('event_id', eventId)
            .or('user_a_id.eq.$maleUserId,user_b_id.eq.$maleUserId');
      } on Object catch (_) {}

      // 2. Male votes for Female
      final maleEmail = await getTestUserEmail(adminClient, gender: 'male');
      await signInAsTestUser(maleEmail);
      await Supabase.instance.client.from('match_votes').insert({
        'event_id': eventId,
        'voter_id': maleUserId,
        'candidate_id': femaleUserId,
      });
      await signOut();

      // 3. Female votes for Male
      final femaleEmail = await getTestUserEmail(adminClient, gender: 'female');
      await signInAsTestUser(femaleEmail);
      await Supabase.instance.client.from('match_votes').insert({
        'event_id': eventId,
        'voter_id': femaleUserId,
        'candidate_id': maleUserId,
      });
      await signOut();

      // 4. Wait for match trigger
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 5. Verify match exists (use admin to bypass RLS)
      final matches = await adminClient
          .from('event_matches')
          .select()
          .eq('event_id', eventId)
          .or(
            'and(user_a_id.eq.$maleUserId,user_b_id.eq.$femaleUserId),'
            'and(user_a_id.eq.$femaleUserId,user_b_id.eq.$maleUserId)',
          ) as List;

      expect(
        matches,
        isNotEmpty,
        reason: 'Mutual votes should create a match',
      );
    });
  });
}
