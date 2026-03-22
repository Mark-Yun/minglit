import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/matching_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

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
          repository.updateMatchRules(
            eventId: 'event_1',
            rules: [],
          ),
          completes,
        );
      });
    });

    group('clearMatchRules', () {
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
    });

    group('castVote', () {
      test('completes when user is authenticated', () async {
        unawaited(mockTable(mockClient, 'match_votes'));

        await expectLater(
          repository.castVote(
            eventId: 'event_1',
            candidateId: 'user_2',
          ),
          completes,
        );
      });

      test('throws when user not authenticated', () async {
        mockClient = createMockSupabase(); // No user
        repository = MatchingRepository(supabase: mockClient);

        expect(
          () => repository.castVote(
            eventId: 'event_1',
            candidateId: 'user_2',
          ),
          throwsA(isA<Exception>()),
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
        unawaited(
          mockTable(
            mockClient,
            'event_participants',
          ),
        );

        final result = await repository.getMatchingCandidates('event_1');
        expect(result, isEmpty);
      });
    });
  });
}
