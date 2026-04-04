@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'golden_test_helpers.dart';

void main() {
  // ---------------------------------------------------------------------------
  // BlockedPartnersPage — empty state
  // ---------------------------------------------------------------------------

  goldenTest(
    'BlockedPartnersPage — empty state',
    fileName: 'blocked_partners_empty',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () {
      final mockRepo = MockSocialRepository();
      when(() => mockRepo.getBlockedPartners()).thenAnswer(
        (_) async => const [],
      );

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'empty (light)',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const BlockedPartnersPage(),
                overrides: [
                  socialRepositoryProvider.overrideWithValue(mockRepo),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'empty (dark)',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const BlockedPartnersPage(),
                brightness: Brightness.dark,
                overrides: [
                  socialRepositoryProvider.overrideWithValue(mockRepo),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  // ---------------------------------------------------------------------------
  // BlockedPartnersPage — with blocked partners
  // ---------------------------------------------------------------------------

  goldenTest(
    'BlockedPartnersPage — with data',
    fileName: 'blocked_partners_with_data',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () {
      final mockRepo = MockSocialRepository();
      when(() => mockRepo.getBlockedPartners()).thenAnswer(
        (_) async => [
          {
            'id': 'p1',
            'name': '소셜 클럽 A',
            'profile_image_url': null,
          },
          {
            'id': 'p2',
            'name': '파티 스튜디오 B',
            'profile_image_url': null,
          },
        ],
      );

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'with data (light)',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const BlockedPartnersPage(),
                overrides: [
                  socialRepositoryProvider.overrideWithValue(mockRepo),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'with data (dark)',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const BlockedPartnersPage(),
                brightness: Brightness.dark,
                overrides: [
                  socialRepositoryProvider.overrideWithValue(mockRepo),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
