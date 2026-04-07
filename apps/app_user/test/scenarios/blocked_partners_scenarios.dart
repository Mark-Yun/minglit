import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../goldens/golden_test_helpers.dart' show MockSocialRepository;
import 'screenshot_scenario.dart';

class BlockedPartnersScenarios {
  static List<dynamic> _emptyOverrides() {
    final mockRepo = MockSocialRepository();
    when(mockRepo.getBlockedPartners).thenAnswer((_) async => const []);
    return [socialRepositoryProvider.overrideWithValue(mockRepo)];
  }

  static List<dynamic> _withDataOverrides() {
    final mockRepo = MockSocialRepository();
    when(mockRepo.getBlockedPartners).thenAnswer(
      (_) async => [
        {'id': 'p1', 'name': '소셜 클럽 A', 'profile_image_url': null},
        {'id': 'p2', 'name': '파티 스튜디오 B', 'profile_image_url': null},
      ],
    );
    return [socialRepositoryProvider.overrideWithValue(mockRepo)];
  }

  static List<ScreenshotScenario> get emptyScenarios => [
    ScreenshotScenario(
      name: 'blocked_partners_empty_light',
      page: const BlockedPartnersPage(),
      overrides: _emptyOverrides(),
    ),
    ScreenshotScenario(
      name: 'blocked_partners_empty_dark',
      page: const BlockedPartnersPage(),
      brightness: Brightness.dark,
      overrides: _emptyOverrides(),
    ),
  ];

  static List<ScreenshotScenario> get withDataScenarios => [
    ScreenshotScenario(
      name: 'blocked_partners_with_data_light',
      page: const BlockedPartnersPage(),
      overrides: _withDataOverrides(),
    ),
    ScreenshotScenario(
      name: 'blocked_partners_with_data_dark',
      page: const BlockedPartnersPage(),
      brightness: Brightness.dark,
      overrides: _withDataOverrides(),
    ),
  ];

  static List<ScreenshotScenario> get all => [
    ...emptyScenarios,
    ...withDataScenarios,
  ];
}
