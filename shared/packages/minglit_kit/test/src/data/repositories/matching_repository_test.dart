import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/matching.dart';
import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/data/repositories/matching_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';
import '../../../helpers/test_utils.dart';

class MockMatchingRepository extends Mock implements MatchingRepository {}

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late MatchingRepository repository;

  final mockUser = MockUser();

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    mockFunctions = mockClient.functions as MockFunctionsClient;
    when(() => mockUser.id).thenReturn('user_1');
    repository = MatchingRepository(supabase: mockClient);
  });

  group('MatchingRepository', () {
    group('getMatchRules', () {
      test('returns match rules for event', () async {
        unawaited(
          mockTable(
            mockClient,
            'match_rules',
            selectData: [
              {
                'id': 'rule_1',
                'event_id': 'event_1',
                'source_group_id': 'group_m',
                'target_group_id': 'group_f',
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          ),
        );

        final result = await repository.getMatchRules('event_1');

        expect(result, hasLength(1));
        expect(result.first.sourceGroupId, 'group_m');
        expect(result.first.targetGroupId, 'group_f');
      });

      test('returns empty list when no rules', () async {
        unawaited(mockTable(mockClient, 'match_rules', selectData: []));

        final result = await repository.getMatchRules('event_none');
        expect(result, isEmpty);
      });
    });

    group('updateMatchRules', () {
      test('completes without error via EF', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-match',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            data: utf8.encode(jsonEncode({'success': true, 'count': 1})),
            status: 200,
          ),
        );

        await expectLater(
          repository.updateMatchRules(
            eventId: 'event_1',
            rules: [
              {
                'source_group_id': 'group_m',
                'target_group_id': 'group_f',
                'vote_count': 3,
              },
            ],
          ),
          completes,
        );
      });

      test('propagates EF error when invoke fails', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-match',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('EF failed'));

        expect(
          () => repository.updateMatchRules(
            eventId: 'event_1',
            rules: [
              {'source_group_id': 'g1', 'target_group_id': 'g2'},
            ],
          ),
          throwsA(isA<Exception>()),
        );
      });

      // Fix #1945: non-200 must throw MinglitUserException
      test('throws MinglitUserException on non-200 response', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-match',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 403,
            data: {'error': '권한이 없습니다.'},
          ),
        );

        await expectLater(
          repository.updateMatchRules(
            eventId: 'event_1',
            rules: [
              {'source_group_id': 'g1', 'target_group_id': 'g2'},
            ],
          ),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('handles empty rules list via EF', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-match',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            data: utf8.encode(jsonEncode({'success': true, 'count': 0})),
            status: 200,
          ),
        );

        await expectLater(
          repository.updateMatchRules(eventId: 'event_1', rules: []),
          completes,
        );
      });
    });

    group('clearMatchRules', () {
      test('propagates EF error when invoke fails', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-match',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('EF failed'));

        expect(
          () => repository.clearMatchRules(eventId: 'event_1'),
          throwsA(isA<Exception>()),
        );
      });

      test('completes without error via EF', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-match',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            data: utf8.encode(jsonEncode({'success': true})),
            status: 200,
          ),
        );

        await expectLater(
          repository.clearMatchRules(eventId: 'event_1'),
          completes,
        );
      });

      // Fix #1945: non-200 must throw MinglitUserException
      test('throws MinglitUserException on non-200 response', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-match',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 500,
            data: {'error': '서버 오류'},
          ),
        );

        await expectLater(
          repository.clearMatchRules(eventId: 'event_1'),
          throwsA(isA<MinglitUserException>()),
        );
      });
    });

    // Fix #306: castVote → EF 전환 후 테스트 업데이트
    group('castVote', () {
      test('completes when EF invoke succeeds', () async {
        when(
          () =>
              mockFunctions.invoke('user-cast-vote', body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            data: utf8.encode(jsonEncode({'success': true})),
            status: 200,
          ),
        );

        await expectLater(
          repository.castVote(eventId: 'event_1', candidateId: 'user_2'),
          completes,
        );
      });

      test('throws when EF invoke fails', () async {
        when(
          () =>
              mockFunctions.invoke('user-cast-vote', body: any(named: 'body')),
        ).thenThrow(Exception('EF failed'));

        expect(
          () => repository.castVote(eventId: 'event_1', candidateId: 'user_2'),
          throwsA(isA<Exception>()),
        );
      });

      // Fix #1945: non-200 must throw MinglitUserException
      test('throws MinglitUserException on non-200 response', () async {
        when(
          () =>
              mockFunctions.invoke('user-cast-vote', body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 409,
            data: {'error': '이미 투표했습니다.'},
          ),
        );

        await expectLater(
          repository.castVote(eventId: 'event_1', candidateId: 'user_2'),
          throwsA(
            isA<MinglitUserException>().having(
              (e) => e.message,
              'message',
              '이미 투표했습니다.',
            ),
          ),
        );
      });
    });

    group('commitMatchLikes', () {
      test('completes when EF invoke succeeds', () async {
        when(
          () => mockFunctions.invoke(
            'commit-match-likes',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            data: utf8.encode(jsonEncode({'success': true, 'inserted_count': 2})),
            status: 200,
          ),
        );

        await expectLater(
          repository.commitMatchLikes(
            eventId: 'event_1',
            candidateIds: const ['user_2', 'user_3'],
          ),
          completes,
        );
      });

      test('throws when EF invoke fails', () async {
        when(
          () => mockFunctions.invoke(
            'commit-match-likes',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('EF failed'));

        expect(
          () => repository.commitMatchLikes(
            eventId: 'event_1',
            candidateIds: const ['user_2'],
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('throws MinglitUserException on non-200 response', () async {
        when(
          () => mockFunctions.invoke(
            'commit-match-likes',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 409,
            data: {'error': '선택 가능한 인원은 최대 3명입니다.'},
          ),
        );

        await expectLater(
          repository.commitMatchLikes(
            eventId: 'event_1',
            candidateIds: const ['user_2', 'user_3', 'user_4', 'user_5'],
          ),
          throwsA(
            isA<MinglitUserException>().having(
              (e) => e.message,
              'message',
              '선택 가능한 인원은 최대 3명입니다.',
            ),
          ),
        );
      });
    });

    group('getMyMatches', () {
      test('returns empty when user not authenticated', () async {
        mockClient = createMockSupabase(); // No user
        repository = MatchingRepository(supabase: mockClient);

        final result = await repository.getMyMatches('event_1');
        expect(result, isEmpty);
      });

      test('returns empty when no matches', () async {
        unawaited(mockTable(mockClient, 'my_matches_view', selectData: []));

        final result = await repository.getMyMatches('event_1');
        expect(result, isEmpty);
      });
    });

    group('getMatchingCandidates', () {
      test('returns empty when user not authenticated', () async {
        mockClient = createMockSupabase(); // No user
        repository = MatchingRepository(supabase: mockClient);

        final result = await repository.getMatchingCandidates('event_1');
        expect(result, isEmpty);
      });

      test('returns empty when no participant record', () async {
        unawaited(mockTable(mockClient, 'event_participants'));

        final result = await repository.getMatchingCandidates('event_1');
        expect(result, isEmpty);

        final participantBuilder = mockTable(
          mockClient,
          'event_participants',
          selectData: [
            {
              'user_id': 'user_2',
              'display_name': '상대방',
              'birth_year': 1996,
              'ticket': {
                'target_entry_group_ids': ['group_f'],
              },
            },
          ],
          maybeSingleData: {
            'ticket': {
              'target_entry_group_ids': ['group_m'],
            },
          },
        );
        // Empty rules → code falls back to gender-based entry_groups path,
        // allowing the entry_groups select() regression guards below to run.
        final rulesBuilder = mockTable(
          mockClient,
          'match_rules',
          selectData: [],
        );
        final entryGroupsBuilder = mockTable(
          mockClient,
          'entry_groups',
          selectData: [
            {'id': 'group_m', 'gender': 'male'},
          ],
        );
        // oppositeGroupsBuilder overwrites entryGroupsBuilder for 'entry_groups'
        // in mocktail, so both entry_groups calls go through this builder.
        // Includes 'gender' so myGender is resolved and the second query runs.
        final oppositeGroupsBuilder = mockTable(
          mockClient,
          'entry_groups',
          selectData: [
            {'id': 'group_f', 'gender': 'female'},
          ],
        );
        unawaited(participantBuilder);
        unawaited(rulesBuilder);
        unawaited(entryGroupsBuilder);
        unawaited(oppositeGroupsBuilder);

        final candidates = await repository.getMatchingCandidates('event_1');

        expect(candidates, hasLength(1));
        // Fix #2011: regression guard — lastSelectColumns must include expected column
        expect(
          rulesBuilder.lastSelectColumns,
          contains('target_group_id'),
          reason: 'Fix #2011: select() must include target_group_id',
        );
        // Fix #2011: regression guard — both entry_groups calls go through
        // oppositeGroupsBuilder because mocktail overwrites stubs with the same
        // table name. Use selectHistory (all calls) to assert 'gender' appeared.
        expect(
          oppositeGroupsBuilder.selectHistory,
          contains('id, gender'),
          reason: 'Fix #2011: select() must include gender',
        );
        // Fix #2011: regression guard — lastSelectColumns must include expected column
        expect(
          oppositeGroupsBuilder.lastSelectColumns,
          contains('id'),
          reason: 'Fix #2011: select() must include id',
        );
        // Fix #2011: regression guard — lastSelectColumns must include expected column
        expect(
          participantBuilder.lastSelectColumns,
          contains('user_id'),
          reason: 'Fix #2011: select() must include user_id',
        );
      });
    });

    // Fix #1959: server-side count path
    group('getMyVoteCount', () {
      test('returns 0 when user is not authenticated', () async {
        mockClient = createMockSupabase(); // no user
        repository = MatchingRepository(supabase: mockClient);

        final result = await repository.getMyVoteCount('event_1');
        expect(result, 0);
      });

      test('returns server-side count from PostgREST count response', () async {
        unawaited(
          mockTable(mockClient, 'match_votes', countValue: 3),
        );

        final result = await repository.getMyVoteCount('event_1');
        expect(result, 3);
      });

      test('passes event_id and voter_id filters to the query', () async {
        final builder = mockTable(
          mockClient,
          'match_votes',
          countValue: 2,
        );

        await repository.getMyVoteCount('event_1');

        final filters = builder.recordedFilters;
        expect(
          filters.any(
            (f) =>
                f.method == 'eq' &&
                f.column == 'event_id' &&
                f.value == 'event_1',
          ),
          isTrue,
          reason: 'Must filter by event_id',
        );
        expect(
          filters.any(
            (f) =>
                f.method == 'eq' &&
                f.column == 'voter_id' &&
                f.value == 'user_1',
          ),
          isTrue,
          reason: 'Must filter by voter_id (current user)',
        );
      });
    });
  });

  group('MatchingRepository providers', () {
    late MockMatchingRepository mockRepository;

    setUp(() {
      mockRepository = MockMatchingRepository();
    });

    test('matchCandidatesProvider returns repository candidates', () async {
      final candidates = <UserProfile>[
        const UserProfile(
          id: 'user_1',
          name: 'Candidate 1',
          username: '',
          birthYear: 1995,
        ),
        const UserProfile(
          id: 'user_2',
          name: 'Candidate 2',
          username: '',
          birthYear: 1993,
        ),
      ];

      when(
        () => mockRepository.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => candidates);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      final result = await container.read(
        matchCandidatesProvider('event_1').future,
      );

      expect(result, candidates);
      verify(() => mockRepository.getMatchingCandidates('event_1')).called(1);
    });

    test('myMatchesProvider returns repository matches', () async {
      final matches = <MatchPair>[
        MatchPair(
          matchId: 'match_1',
          eventId: 'event_1',
          partnerId: 'partner_1',
          matchedAt: DateTime(2026, 3, 30),
        ),
      ];

      when(
        () => mockRepository.getMyMatches('event_1'),
      ).thenAnswer((_) async => matches);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      final result = await container.read(myMatchesProvider('event_1').future);

      expect(result, matches);
      verify(() => mockRepository.getMyMatches('event_1')).called(1);
    });

    test('myVoteCountProvider returns repository vote count', () async {
      when(
        () => mockRepository.getMyVoteCount('event_1'),
      ).thenAnswer((_) async => 3);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      final result = await container.read(
        myVoteCountProvider('event_1').future,
      );

      expect(result, 3);
      verify(() => mockRepository.getMyVoteCount('event_1')).called(1);
    });

    test(
      'myVotedCandidateIdsProvider returns repository candidate ids',
      () async {
        when(
          () => mockRepository.getMyVotedCandidateIds('event_1'),
        ).thenAnswer((_) async => {'candidate_1', 'candidate_2'});

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final result = await container.read(
          myVotedCandidateIdsProvider('event_1').future,
        );

        expect(result, {'candidate_1', 'candidate_2'});
        verify(
          () => mockRepository.getMyVotedCandidateIds('event_1'),
        ).called(1);
      },
    );

    test('maxVoteCountProvider returns 1 when rules are empty', () async {
      when(
        () => mockRepository.getMatchRules('event_empty'),
      ).thenAnswer((_) async => const []);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      final result = await container.read(
        maxVoteCountProvider('event_empty').future,
      );

      expect(result, 1);
      verify(() => mockRepository.getMatchRules('event_empty')).called(1);
    });

    test(
      'maxVoteCountProvider returns the highest configured vote count',
      () async {
        when(() => mockRepository.getMatchRules('event_1')).thenAnswer(
          (_) async => [
            MatchRule(
              id: 'rule_1',
              eventId: 'event_1',
              sourceGroupId: 'group_a',
              targetGroupId: 'group_b',
              createdAt: DateTime(2026, 3, 30),
              voteCount: 2,
            ),
            MatchRule(
              id: 'rule_2',
              eventId: 'event_1',
              sourceGroupId: 'group_a',
              targetGroupId: 'group_c',
              createdAt: DateTime(2026, 3, 30),
              voteCount: 5,
            ),
            MatchRule(
              id: 'rule_3',
              eventId: 'event_1',
              sourceGroupId: 'group_a',
              targetGroupId: 'group_d',
              createdAt: DateTime(2026, 3, 30),
              voteCount: 3,
            ),
          ],
        );

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final result = await container.read(
          maxVoteCountProvider('event_1').future,
        );

        expect(result, 5);
        verify(() => mockRepository.getMatchRules('event_1')).called(1);
      },
    );
  });
}
