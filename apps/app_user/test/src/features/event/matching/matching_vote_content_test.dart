import 'package:app_user/src/features/event/matching/matching_vote_content.dart';
import 'package:app_user/src/features/event/matching/matching_vote_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('MatchingVoteContent', () {
    testWidgets('renders empty state when no candidates',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchCandidatesProvider('event_1')
                .overrideWith((_) async => <UserProfile>[]),
            myMatchesProvider('event_1')
                .overrideWith((_) async => <MatchPair>[]),
            myVoteCountProvider('event_1')
                .overrideWith((_) async => 0),
            maxVoteCountProvider('event_1')
                .overrideWith((_) async => 3),
            myVotedCandidateIdsProvider('event_1')
                .overrideWith((_) async => <String>{}),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MatchingVoteContent(eventId: 'event_1'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(
        find.text('투표 가능한 상대가 없습니다.'),
        findsOneWidget,
      );
    });

    testWidgets('renders candidates when data is available',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchCandidatesProvider('event_1').overrideWith(
              (_) async => [
                UserProfile(
                  id: 'c1',
                  name: 'Alice',
                  username: 'alice',
                  createdAt: DateTime(2024),
                  updatedAt: DateTime(2024),
                ),
              ],
            ),
            myMatchesProvider('event_1')
                .overrideWith((_) async => <MatchPair>[]),
            myVoteCountProvider('event_1')
                .overrideWith((_) async => 0),
            maxVoteCountProvider('event_1')
                .overrideWith((_) async => 3),
            myVotedCandidateIdsProvider('event_1')
                .overrideWith((_) async => <String>{}),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MatchingVoteContent(eventId: 'event_1'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('선택'), findsOneWidget);
    });

    testWidgets('can be embedded without Scaffold',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchCandidatesProvider('event_1')
                .overrideWith((_) async => <UserProfile>[]),
            myMatchesProvider('event_1')
                .overrideWith((_) async => <MatchPair>[]),
            myVoteCountProvider('event_1')
                .overrideWith((_) async => 0),
            maxVoteCountProvider('event_1')
                .overrideWith((_) async => 3),
            myVotedCandidateIdsProvider('event_1')
                .overrideWith((_) async => <String>{}),
          ],
          child: MaterialApp(
            home: SizedBox(
              height: 400,
              child: MatchingVoteContent(eventId: 'event_1'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(
        find.byType(MatchingVoteContent),
        findsOneWidget,
      );
    });
  });
}
