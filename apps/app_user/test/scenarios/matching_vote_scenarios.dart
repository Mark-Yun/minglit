import 'package:app_user/src/features/event/matching/matching_vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'screenshot_scenario.dart';

class MatchingVoteScenarios {
  static final _now = DateTime(2026, 4, 1, 20);

  static List<UserProfile> get _candidates => [
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

  static List<MatchPair> get _matched => [
    MatchPair(
      matchId: 'match-1',
      eventId: 'event-1',
      partnerId: 'user-4',
      matchedAt: _now,
      partnerName: '지민',
      partnerContact: '010-1234-5678',
    ),
  ];

  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'matching_vote_screen_remaining_votes',
      page: const MatchingVoteScreen(eventId: 'event-1'),
      overrides: [
        matchCandidatesProvider('event-1').overrideWith((_) async => _candidates),
        myMatchesProvider('event-1').overrideWith((_) async => []),
        myVoteCountProvider('event-1').overrideWith((_) async => 0),
        maxVoteCountProvider('event-1').overrideWith((_) async => 2),
        myVotedCandidateIdsProvider('event-1').overrideWith(
          (_) async => <String>{},
        ),
      ],
    ),
    ScreenshotScenario(
      name: 'matching_vote_screen_completed',
      page: const MatchingVoteScreen(eventId: 'event-1'),
      brightness: Brightness.dark,
      overrides: [
        matchCandidatesProvider('event-1').overrideWith((_) async => _candidates),
        myMatchesProvider('event-1').overrideWith((_) async => _matched),
        myVoteCountProvider('event-1').overrideWith((_) async => 2),
        maxVoteCountProvider('event-1').overrideWith((_) async => 2),
        myVotedCandidateIdsProvider('event-1').overrideWith(
          (_) async => {'user-2', 'user-3'},
        ),
      ],
    ),
  ];
}
