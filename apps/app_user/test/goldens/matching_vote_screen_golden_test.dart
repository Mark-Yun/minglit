@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/event/matching/matching_vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initGoldenDeps();
  });

  final now = DateTime(2026, 4, 1, 20);
  final candidates = [
    UserProfile(
      id: 'user-2',
      name: '한나',
      username: 'hanna',
      gender: 'female',
      birthDate: DateTime(1997, 5, 10),
    ),
    UserProfile(
      id: 'user-3',
      name: '수진',
      username: 'sujin',
      gender: 'female',
      birthDate: DateTime(1996, 8, 3),
    ),
  ];

  final matched = [
    MatchPair(
      matchId: 'match-1',
      eventId: 'event-1',
      partnerId: 'user-4',
      matchedAt: now,
      partnerName: '지민',
      partnerContact: '010-1234-5678',
    ),
  ];

  goldenTest(
    'MatchingVoteScreen with remaining votes',
    fileName: 'matching_vote_screen_remaining_votes',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'remaining votes',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const MatchingVoteScreen(eventId: 'event-1'),
              overrides: [
                matchCandidatesProvider(
                  'event-1',
                ).overrideWith((_) async => candidates),
                myMatchesProvider('event-1').overrideWith((_) async => []),
                myVoteCountProvider('event-1').overrideWith((_) async => 0),
                maxVoteCountProvider('event-1').overrideWith((_) async => 2),
                myVotedCandidateIdsProvider(
                  'event-1',
                ).overrideWith((_) async => <String>{}),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'MatchingVoteScreen after all votes used',
    fileName: 'matching_vote_screen_completed',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'completed votes',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const MatchingVoteScreen(eventId: 'event-1'),
              brightness: Brightness.dark,
              overrides: [
                matchCandidatesProvider(
                  'event-1',
                ).overrideWith((_) async => candidates),
                myMatchesProvider('event-1').overrideWith((_) async => matched),
                myVoteCountProvider('event-1').overrideWith((_) async => 2),
                maxVoteCountProvider('event-1').overrideWith((_) async => 2),
                myVotedCandidateIdsProvider(
                  'event-1',
                ).overrideWith((_) async => {'user-2', 'user-3'}),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
