import 'package:app_user/src/features/event/matching/matching_vote_controller.dart';
import 'package:app_user/src/features/event/matching/matching_vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  late MockMatchingRepository mockMatchingRepo;

  setUp(() {
    mockMatchingRepo = MockMatchingRepository();
  });

  /// Sets up mock repository with given data and pumps [MatchingVoteContent].
  Future<void> pumpContent(
    WidgetTester tester, {
    List<UserProfile> candidates = const [],
    List<MatchPair> matches = const [],
    int voteCount = 0,
    int maxVotes = 3,
    Set<String> votedIds = const {},
  }) async {
    when(
      () => mockMatchingRepo.getMatchingCandidates('test-event'),
    ).thenAnswer((_) async => candidates);
    when(
      () => mockMatchingRepo.getMyMatches('test-event'),
    ).thenAnswer((_) async => matches);
    when(
      () => mockMatchingRepo.getMyVoteCount('test-event'),
    ).thenAnswer((_) async => voteCount);
    when(
      () => mockMatchingRepo.getMyVotedCandidateIds('test-event'),
    ).thenAnswer((_) async => votedIds);
    when(
      () => mockMatchingRepo.getMatchRules('test-event'),
    ).thenAnswer(
      (_) async => [
        MatchRule(
          id: 'rule_1',
          eventId: 'test-event',
          sourceGroupId: 'a',
          targetGroupId: 'b',
          voteCount: maxVotes,
          createdAt: DateTime(2026),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MatchingVoteContent(eventId: 'test-event'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MatchingVoteContent', () {
    testWidgets('renders without its own Scaffold', (tester) async {
      await pumpContent(tester);

      expect(find.byType(MatchingVoteContent), findsOneWidget);
      // MatchingVoteContent should NOT contain a Scaffold
      final scaffoldFinder = find.descendant(
        of: find.byType(MatchingVoteContent),
        matching: find.byType(Scaffold),
      );
      expect(scaffoldFinder, findsNothing);
    });

    testWidgets('shows empty state when no candidates', (tester) async {
      await pumpContent(tester);

      expect(find.text('투표 가능한 상대가 없습니다.'), findsOneWidget);
    });

    testWidgets('displays candidate cards with vote buttons', (tester) async {
      await pumpContent(
        tester,
        candidates: const [
          UserProfile(
            id: 'c1',
            name: 'Alice',
            username: 'alice',
            birthYear: 1995,
          ),
          UserProfile(
            id: 'c2',
            name: 'Bob',
            username: 'bob',
            birthYear: 1993,
          ),
        ],
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('선택'), findsNWidgets(2));
    });

    testWidgets('shows remaining vote count', (tester) async {
      await pumpContent(
        tester,
        candidates: const [
          UserProfile(
            id: 'c1',
            name: 'Alice',
            username: 'alice',
            birthYear: 1995,
          ),
        ],
        voteCount: 1,
        maxVotes: 3,
      );

      expect(find.text('남은 투표: 2/3'), findsOneWidget);
    });

    testWidgets('shows vote complete state when all votes used',
        (tester) async {
      await pumpContent(
        tester,
        candidates: const [
          UserProfile(
            id: 'c1',
            name: 'Alice',
            username: 'alice',
            birthYear: 1995,
          ),
        ],
        voteCount: 3,
        maxVotes: 3,
      );

      expect(find.text('투표 완료!'), findsOneWidget);
    });

    testWidgets('marks voted candidates', (tester) async {
      await pumpContent(
        tester,
        candidates: const [
          UserProfile(
            id: 'c1',
            name: 'Alice',
            username: 'alice',
            birthYear: 1995,
          ),
          UserProfile(
            id: 'c2',
            name: 'Bob',
            username: 'bob',
            birthYear: 1993,
          ),
        ],
        votedIds: {'c1'},
      );

      // c1 voted → "투표 완료" button, c2 not voted → "선택" button
      expect(find.text('투표 완료'), findsOneWidget);
      expect(find.text('선택'), findsOneWidget);
    });

    testWidgets('displays match section when matches exist', (tester) async {
      await pumpContent(
        tester,
        matches: [
          MatchPair(
            matchId: 'm1',
            eventId: 'test-event',
            partnerId: 'p1',
            partnerName: 'Charlie',
            partnerContact: '010-1234-5678',
            matchedAt: DateTime(2026, 3, 29),
          ),
        ],
      );

      expect(find.textContaining('매칭 성공!'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('010-1234-5678'), findsOneWidget);
    });
  });
}
