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

  Widget buildSubject({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ...overrides,
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const Scaffold(
          body: MatchingVoteContent(eventId: 'event_1'),
        ),
      ),
    );
  }

  group('MatchingVoteContent', () {
    testWidgets('renders without Scaffold — embeddable standalone', (
      tester,
    ) async {
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => <UserProfile>[]);
      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer((_) async => <MatchPair>[]);
      when(
        () => mockMatchingRepo.getMyVoteCount('event_1'),
      ).thenAnswer((_) async => 0);
      when(
        () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
      ).thenAnswer((_) async => <String>{});
      when(
        () => mockMatchingRepo.getMatchRules('event_1'),
      ).thenAnswer(
        (_) async => [
          MatchRule(
            id: 'rule_1',
            eventId: 'event_1',
            sourceGroupId: 'g1',
            targetGroupId: 'g2',
            createdAt: DateTime(2026),
            voteCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // MatchingVoteContent itself should not introduce a Scaffold
      // The outer Scaffold in buildSubject is the only one
      expect(find.byType(MatchingVoteContent), findsOneWidget);
      expect(find.text('투표 가능한 상대가 없습니다.'), findsOneWidget);
    });

    testWidgets('shows candidates in grid when data loaded', (tester) async {
      final candidates = [
        const UserProfile(
          id: 'user_1',
          name: 'Alice',
          username: '',
          birthYear: 1995,
        ),
        const UserProfile(
          id: 'user_2',
          name: 'Bob',
          username: '',
          birthYear: 1993,
        ),
      ];

      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => candidates);
      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer((_) async => <MatchPair>[]);
      when(
        () => mockMatchingRepo.getMyVoteCount('event_1'),
      ).thenAnswer((_) async => 0);
      when(
        () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
      ).thenAnswer((_) async => <String>{});
      when(
        () => mockMatchingRepo.getMatchRules('event_1'),
      ).thenAnswer(
        (_) async => [
          MatchRule(
            id: 'rule_1',
            eventId: 'event_1',
            sourceGroupId: 'g1',
            targetGroupId: 'g2',
            createdAt: DateTime(2026),
            voteCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      // Two '선택' buttons for unvoted candidates
      expect(find.text('선택'), findsNWidgets(2));
    });

    testWidgets('shows remaining votes count', (tester) async {
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => <UserProfile>[]);
      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer((_) async => <MatchPair>[]);
      when(
        () => mockMatchingRepo.getMyVoteCount('event_1'),
      ).thenAnswer((_) async => 1);
      when(
        () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
      ).thenAnswer((_) async => <String>{'user_1'});
      when(
        () => mockMatchingRepo.getMatchRules('event_1'),
      ).thenAnswer(
        (_) async => [
          MatchRule(
            id: 'rule_1',
            eventId: 'event_1',
            sourceGroupId: 'g1',
            targetGroupId: 'g2',
            createdAt: DateTime(2026),
            voteCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('남은 투표: 2/3'), findsOneWidget);
    });

    testWidgets('shows 투표 완료 when all votes used', (tester) async {
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => <UserProfile>[]);
      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer((_) async => <MatchPair>[]);
      when(
        () => mockMatchingRepo.getMyVoteCount('event_1'),
      ).thenAnswer((_) async => 3);
      when(
        () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
      ).thenAnswer((_) async => <String>{'u1', 'u2', 'u3'});
      when(
        () => mockMatchingRepo.getMatchRules('event_1'),
      ).thenAnswer(
        (_) async => [
          MatchRule(
            id: 'rule_1',
            eventId: 'event_1',
            sourceGroupId: 'g1',
            targetGroupId: 'g2',
            createdAt: DateTime(2026),
            voteCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('투표 완료!'), findsOneWidget);
    });

    testWidgets('shows match success section when matches exist', (
      tester,
    ) async {
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => <UserProfile>[]);
      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer(
        (_) async => [
          MatchPair(
            matchId: 'm1',
            eventId: 'event_1',
            partnerId: 'p1',
            matchedAt: DateTime(2026),
            partnerName: 'Charlie',
            partnerContact: '010-1234-5678',
          ),
        ],
      );
      when(
        () => mockMatchingRepo.getMyVoteCount('event_1'),
      ).thenAnswer((_) async => 0);
      when(
        () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
      ).thenAnswer((_) async => <String>{});
      when(
        () => mockMatchingRepo.getMatchRules('event_1'),
      ).thenAnswer(
        (_) async => [
          MatchRule(
            id: 'rule_1',
            eventId: 'event_1',
            sourceGroupId: 'g1',
            targetGroupId: 'g2',
            createdAt: DateTime(2026),
          ),
        ],
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('매칭 성공! (1명)'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('010-1234-5678'), findsOneWidget);
    });
  });

  group('MatchingVoteScreen', () {
    testWidgets('wraps MatchingVoteContent in Scaffold with AppBar', (
      tester,
    ) async {
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => <UserProfile>[]);
      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer((_) async => <MatchPair>[]);
      when(
        () => mockMatchingRepo.getMyVoteCount('event_1'),
      ).thenAnswer((_) async => 0);
      when(
        () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
      ).thenAnswer((_) async => <String>{});
      when(
        () => mockMatchingRepo.getMatchRules('event_1'),
      ).thenAnswer(
        (_) async => [
          MatchRule(
            id: 'rule_1',
            eventId: 'event_1',
            sourceGroupId: 'g1',
            targetGroupId: 'g2',
            createdAt: DateTime(2026),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ],
          child: MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: const MatchingVoteScreen(eventId: 'event_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('매칭 투표'), findsOneWidget); // AppBar title
      expect(find.byType(MatchingVoteContent), findsOneWidget);
    });
  });
}
