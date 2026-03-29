import 'package:app_user/src/features/event/matching/matching_vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  late MockMatchingRepository mockMatchingRepo;

  setUp(() {
    mockMatchingRepo = MockMatchingRepository();
  });

  Widget createTestWidget({
    String eventId = 'event_1',
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ...overrides,
      ].cast(),
      child: MaterialApp(
        home: Scaffold(
          body: MatchingVoteContent(eventId: eventId),
        ),
      ),
    );
  }

  void stubDefaultProviders({
    List<UserProfile> candidates = const [],
    List<MatchPair> matches = const [],
    int voteCount = 0,
    int maxVotes = 3,
    Set<String> votedIds = const {},
  }) {
    when(
      () => mockMatchingRepo.getMatchingCandidates('event_1'),
    ).thenAnswer((_) async => candidates);
    when(
      () => mockMatchingRepo.getMyMatches('event_1'),
    ).thenAnswer((_) async => matches);
    when(
      () => mockMatchingRepo.getMyVoteCount('event_1'),
    ).thenAnswer((_) async => voteCount);
    when(
      () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
    ).thenAnswer((_) async => votedIds);
    when(() => mockMatchingRepo.getMatchRules('event_1')).thenAnswer(
      (_) async => [
        MatchRule(
          id: 'rule_1',
          eventId: 'event_1',
          sourceGroupId: 'g_1',
          targetGroupId: 'g_2',
          voteCount: maxVotes,
          createdAt: DateTime(2024),
        ),
      ],
    );
  }

  group('MatchingVoteContent', () {
    testWidgets('renders without Scaffold — embeddable in any host', (
      tester,
    ) async {
      stubDefaultProviders();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // MatchingVoteContent itself does not contain a Scaffold
      // The test wraps it in one, so exactly 1 Scaffold should exist
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(MatchingVoteContent), findsOneWidget);
    });

    testWidgets('shows empty state when no candidates', (tester) async {
      stubDefaultProviders();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('투표 가능한 상대가 없습니다.'), findsOneWidget);
    });

    testWidgets('renders candidate cards with vote buttons', (tester) async {
      stubDefaultProviders(
        candidates: [
          const UserProfile(
            id: 'c_1',
            name: '홍길동',
            username: 'hong',
          ),
          const UserProfile(
            id: 'c_2',
            name: '김철수',
            username: 'kim',
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김철수'), findsOneWidget);
      expect(find.text('선택'), findsNWidgets(2));
    });

    testWidgets('shows remaining vote count', (tester) async {
      stubDefaultProviders(
        candidates: [
          const UserProfile(id: 'c_1', name: '홍길동', username: 'hong'),
        ],
        voteCount: 1,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('남은 투표: 2/3'), findsOneWidget);
    });

    testWidgets('shows vote complete when all votes used', (tester) async {
      stubDefaultProviders(
        candidates: [
          const UserProfile(id: 'c_1', name: '홍길동', username: 'hong'),
        ],
        voteCount: 3,
        votedIds: {'c_1'},
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('투표 완료!'), findsOneWidget);
      // Candidate button should show '투표 완료' instead of '선택'
      expect(find.text('투표 완료'), findsOneWidget);
    });

    testWidgets('shows match section when matches exist', (tester) async {
      stubDefaultProviders(
        candidates: [
          const UserProfile(id: 'c_1', name: '홍길동', username: 'hong'),
        ],
        matches: [
          MatchPair(
            matchId: 'm_1',
            eventId: 'event_1',
            partnerId: 'p_1',
            matchedAt: DateTime(2024),
            partnerName: '이영희',
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('매칭 성공! (1명)'), findsOneWidget);
      expect(find.text('이영희'), findsOneWidget);
    });

    testWidgets('MatchingVoteScreen wraps content with Scaffold and AppBar', (
      tester,
    ) async {
      stubDefaultProviders();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ].cast(),
          child: const MaterialApp(
            home: MatchingVoteScreen(eventId: 'event_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('매칭 투표'), findsOneWidget);
      expect(find.byType(MatchingVoteContent), findsOneWidget);
    });
  });
}
