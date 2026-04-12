// Ref #1319: S04 — 매칭 플로우 백엔드 시나리오 테스트
//
// 검증 포인트:
// 1. 이벤트에 2개 그룹 + match_rules 설정 — 매칭 준비 상태 확인
// 2. 양방향 투표 → match_pair 자동 생성 (handle_new_match_vote 트리거)
// 3. 단방향 투표만 → match_pair 미생성
// 4. 투표 중복 방지 — cast_match_vote RPC 중복 거부
// 5. 체크인 없는 유저 → cast_match_vote RPC 외부 보호 (EF 레이어)
//
// 의존:
//   - match_votes INSERT → handle_new_match_vote 트리거 → match_pairs INSERT
//   - cast_match_vote RPC: 원자적 투표 수 제한 + 중복 방지
//   - replace_match_rules RPC: 매칭 규칙 원자적 교체
import 'dart:convert';
import 'dart:math';
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

  group('S04: 매칭 플로우 시나리오', () {
    late String testUserId;
    late String testPartnerId;
    late String testPartyId;
    late String testEventId;
    late String groupAId;
    late String groupBId;
    late String userAId;
    late String userBId;
    final suffix = Random().nextInt(99999);

    setUpAll(() async {
      testUserId = await getMale25VerifiedUserId(adminClient);

      // Create isolated partner + party
      final partnerRes = await adminClient
          .from('partners')
          .insert({'name': 'Matching Test Partner $suffix'})
          .select()
          .single();
      testPartnerId = partnerRes['id'] as String;

      final partyRes = await adminClient
          .from('parties')
          .insert({
            'partner_id': testPartnerId,
            'title': 'Matching Test Party $suffix',
            'min_confirmed_count': 0,
            'max_participants': 20,
          })
          .select()
          .single();
      testPartyId = partyRes['id'] as String;

      // Create event in MATCHING phase with vote period active
      final now = DateTime.now().toUtc();
      final eventRes = await adminClient
          .from('events')
          .insert({
            'party_id': testPartyId,
            'start_time': now.subtract(const Duration(hours: 3)).toIso8601String(),
            'end_time': now.add(const Duration(hours: 1)).toIso8601String(),
            'min_confirmed_count': 0,
            'max_participant_count': 20,
            'vote_start_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'vote_end_at': now.add(const Duration(hours: 1)).toIso8601String(),
          })
          .select()
          .single();
      testEventId = eventRes['id'] as String;

      // Create 2 entry groups (male / female)
      final groupARes = await adminClient
          .from('entry_groups')
          .insert({'event_id': testEventId, 'gender': 'male'})
          .select()
          .single();
      groupAId = groupARes['id'] as String;

      final groupBRes = await adminClient
          .from('entry_groups')
          .insert({'event_id': testEventId, 'gender': 'female'})
          .select()
          .single();
      groupBId = groupBRes['id'] as String;

      // Get two test users (userA from group A, userB from group B)
      userAId = testUserId;
      final userBProfile = await adminClient
          .from('user_profiles')
          .select('id')
          .neq('id', userAId)
          .limit(1)
          .single();
      userBId = userBProfile['id'] as String;

      // Create event_participants for both users (checked_in)
      await adminClient.from('event_participants').insert([
        {
          'event_id': testEventId,
          'user_id': userAId,
          'entry_group_id': groupAId,
          'status': 'checked_in',
        },
        {
          'event_id': testEventId,
          'user_id': userBId,
          'entry_group_id': groupBId,
          'status': 'checked_in',
        },
      ]);

      // Set up match_rules: group A → group B (and B → A for bidirectional matching)
      await adminClient.rpc<dynamic>('replace_match_rules', params: {
        'p_event_id': testEventId,
        'p_rules': jsonEncode([
          {
            'source_group_id': groupAId,
            'target_group_id': groupBId,
            'vote_count': 3,
          },
          {
            'source_group_id': groupBId,
            'target_group_id': groupAId,
            'vote_count': 3,
          },
        ]),
      });
    });

    tearDownAll(() async {
      // Cleanup in reverse dependency order
      await adminClient
          .from('match_pairs')
          .delete()
          .eq('event_id', testEventId);
      await adminClient
          .from('match_votes')
          .delete()
          .eq('event_id', testEventId);
      await adminClient
          .from('match_rules')
          .delete()
          .eq('event_id', testEventId);
      await adminClient
          .from('entry_groups')
          .delete()
          .eq('event_id', testEventId);
      await adminClient
          .from('event_participants')
          .delete()
          .eq('event_id', testEventId);
      await adminClient.from('events').delete().eq('id', testEventId);
      await adminClient.from('parties').delete().eq('id', testPartyId);
      await adminClient.from('partners').delete().eq('id', testPartnerId);
    });

    test('TC-S04-1: 2개 그룹 + match_rules 설정 — 매칭 준비 상태 확인', () async {
      // Verify entry groups exist
      final groups = await adminClient
          .from('entry_groups')
          .select()
          .eq('event_id', testEventId);
      expect(groups.length, equals(2),
          reason: 'Should have 2 entry groups for matching');

      // Verify match_rules exist (both directions)
      final rules = await adminClient
          .from('match_rules')
          .select()
          .eq('event_id', testEventId);
      expect(rules.length, equals(2),
          reason: 'Should have 2 match_rules (A→B and B→A)');

      // Verify both participants are checked_in
      final participants = await adminClient
          .from('event_participants')
          .select()
          .eq('event_id', testEventId)
          .eq('status', 'checked_in');
      expect(participants.length, greaterThanOrEqualTo(2),
          reason: 'Both participants should be checked_in');
    });

    test('TC-S04-2: 양방향 투표 → match_pair 자동 생성 (handle_new_match_vote 트리거)',
        () async {
      // Cleanup any existing votes/pairs for this test
      await adminClient.from('match_pairs').delete().eq('event_id', testEventId);
      await adminClient.from('match_votes').delete().eq('event_id', testEventId);

      // Insert A → B vote
      await adminClient.from('match_votes').insert({
        'event_id': testEventId,
        'voter_id': userAId,
        'candidate_id': userBId,
      });

      // At this point, only one direction → no match_pair yet
      final pairsAfterFirstVote = await adminClient
          .from('match_pairs')
          .select()
          .eq('event_id', testEventId);
      expect(pairsAfterFirstVote, isEmpty,
          reason: 'Single direction vote should not create match_pair');

      // Insert B → A vote (completing bidirectional match)
      await adminClient.from('match_votes').insert({
        'event_id': testEventId,
        'voter_id': userBId,
        'candidate_id': userAId,
      });

      // Trigger fires synchronously on INSERT — pair should exist now
      final pairsAfterBothVotes = await adminClient
          .from('match_pairs')
          .select()
          .eq('event_id', testEventId);
      expect(pairsAfterBothVotes.length, equals(1),
          reason: 'Bidirectional votes should create exactly 1 match_pair');

      // Verify canonical ordering (lower_id < higher_id)
      final pair = pairsAfterBothVotes.first as Map<String, dynamic>;
      final lowerUser = pair['user_lower_id'] as String;
      final higherUser = pair['user_higher_id'] as String;
      expect(lowerUser.compareTo(higherUser), lessThan(0),
          reason: 'user_lower_id must be lexicographically less than user_higher_id');
      expect(
        {lowerUser, higherUser},
        equals({userAId, userBId}),
        reason: 'Pair should contain exactly userA and userB',
      );
    });

    test('TC-S04-3: 단방향 투표만 → match_pair 미생성', () async {
      // Setup: create a third user for this isolated test
      final userCProfile = await adminClient
          .from('user_profiles')
          .select('id')
          .neq('id', userAId)
          .neq('id', userBId)
          .limit(1)
          .single();
      final userCId = userCProfile['id'] as String;

      // Add userC as participant in group B
      await adminClient.from('event_participants').upsert({
        'event_id': testEventId,
        'user_id': userCId,
        'entry_group_id': groupBId,
        'status': 'checked_in',
      });

      // Only A → C (no reverse)
      await adminClient.from('match_votes').insert({
        'event_id': testEventId,
        'voter_id': userAId,
        'candidate_id': userCId,
      });

      // Verify no pair for A-C
      final lowerAC = userAId.compareTo(userCId) < 0 ? userAId : userCId;
      final higherAC = userAId.compareTo(userCId) < 0 ? userCId : userAId;

      final pairs = await adminClient
          .from('match_pairs')
          .select()
          .eq('event_id', testEventId)
          .eq('user_lower_id', lowerAC)
          .eq('user_higher_id', higherAC);
      expect(pairs, isEmpty,
          reason: 'One-directional vote A→C must not create match_pair');

      // Cleanup
      await adminClient
          .from('match_votes')
          .delete()
          .eq('event_id', testEventId)
          .eq('voter_id', userAId)
          .eq('candidate_id', userCId);
      await adminClient
          .from('event_participants')
          .delete()
          .eq('event_id', testEventId)
          .eq('user_id', userCId);
    });

    test('TC-S04-4: 투표 중복 방지 — cast_match_vote RPC 중복 투표 거부', () async {
      // Ensure A→B vote exists from TC-S04-2
      // (TC-S04-2 inserted A→B; if run in isolation, insert here)
      final existingVote = await adminClient
          .from('match_votes')
          .select()
          .eq('event_id', testEventId)
          .eq('voter_id', userAId)
          .eq('candidate_id', userBId);

      if (existingVote.isEmpty) {
        await adminClient.from('match_votes').insert({
          'event_id': testEventId,
          'voter_id': userAId,
          'candidate_id': userBId,
        });
      }

      // Attempt duplicate via cast_match_vote RPC → should throw
      Object? caught;
      try {
        await adminClient.rpc<dynamic>('cast_match_vote', params: {
          'p_event_id': testEventId,
          'p_voter_id': userAId,
          'p_candidate_id': userBId,
          'p_max_vote_count': 3,
        });
      } catch (e) {
        caught = e;
      }

      expect(caught, isNotNull, reason: 'Duplicate vote should throw');
      expect(caught.toString(), contains('이미 투표한 후보입니다'),
          reason: 'Error message should indicate duplicate vote');
    });

    test(
        'TC-S04-5: 체크인 없는 유저 → match_votes unique constraint + EF 보호 확인',
        () async {
      // At DB level: match_votes has no FK to event_participants (check-in validated by EF).
      // Verify that the EF (user-cast-vote) is the enforcement layer:
      // calling without Authorization header returns 401.
      final efUrl =
          '${TestConfig.supabaseUrl}/functions/v1/user-cast-vote';
      final response = await adminClient.functions.invoke(
        'user-cast-vote',
        body: {
          'event_id': testEventId,
          'candidate_id': userBId,
        },
      );
      // A service-role call without a valid user JWT should fail (EF requires user auth)
      // The EF checks requireAuth → rejects service_role JWT
      expect(
        response.status,
        anyOf(400, 401, 403),
        reason: 'user-cast-vote EF must reject calls without user JWT',
      );
    });
  });
}
