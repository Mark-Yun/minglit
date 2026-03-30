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
  late String maleEmail;
  late String femaleEmail;
  late String eventId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    maleEmail = await getTestUserEmail(adminClient, gender: 'male');
    femaleEmail = await getTestUserEmail(adminClient, gender: 'female');

    await signInAsTestUser(maleEmail);
    maleUserId = Supabase.instance.client.auth.currentUser!.id;
    await signOut();

    await signInAsTestUser(femaleEmail);
    femaleUserId = Supabase.instance.client.auth.currentUser!.id;
    await signOut();

    final ctx = await findScheduledEvent(adminClient);
    eventId = ctx.eventId;

    // Cleanup leftover data
    await _cleanup(adminClient, eventId, maleUserId, femaleUserId);
  });

  tearDownAll(() async {
    await _cleanup(adminClient, eventId, maleUserId, femaleUserId);
    await signOut();
  });

  group('CUJ 04: Matching', () {
    testWidgets('남성 유저가 여성 유저에게 투표할 수 있다', (tester) async {
      await signInAsTestUser(maleEmail);
      await Supabase.instance.client.from('match_votes').insert({
        'event_id': eventId,
        'voter_id': maleUserId,
        'candidate_id': femaleUserId,
      });
      await signOut();

      final vote = await adminClient
          .from('match_votes')
          .select()
          .eq('event_id', eventId)
          .eq('voter_id', maleUserId)
          .eq('candidate_id', femaleUserId)
          .maybeSingle();
      expect(vote, isNotNull, reason: 'Vote should be recorded');
    });

    testWidgets('여성 유저가 남성 유저에게 투표할 수 있다', (tester) async {
      await signInAsTestUser(femaleEmail);
      await Supabase.instance.client.from('match_votes').insert({
        'event_id': eventId,
        'voter_id': femaleUserId,
        'candidate_id': maleUserId,
      });
      await signOut();

      final vote = await adminClient
          .from('match_votes')
          .select()
          .eq('event_id', eventId)
          .eq('voter_id', femaleUserId)
          .eq('candidate_id', maleUserId)
          .maybeSingle();
      expect(vote, isNotNull, reason: 'Vote should be recorded');
    });

    testWidgets('상호 투표 시 매치가 생성된다', (tester) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final matches = await adminClient
          .from('event_matches')
          .select()
          .eq('event_id', eventId)
          .or(
            'and(user_a_id.eq.$maleUserId,user_b_id.eq.$femaleUserId),'
            'and(user_a_id.eq.$femaleUserId,user_b_id.eq.$maleUserId)',
          ) as List;

      expect(matches, isNotEmpty, reason: 'Mutual votes should create a match');
    });
  });
}

Future<void> _cleanup(
  SupabaseClient admin,
  String eventId,
  String maleUserId,
  String femaleUserId,
) async {
  try {
    await admin
        .from('match_votes')
        .delete()
        .eq('event_id', eventId)
        .inFilter('voter_id', [maleUserId, femaleUserId]);
  } on Object catch (_) {}
  try {
    await admin
        .from('event_matches')
        .delete()
        .eq('event_id', eventId)
        .or('user_a_id.eq.$maleUserId,user_b_id.eq.$maleUserId');
  } on Object catch (_) {}
}
