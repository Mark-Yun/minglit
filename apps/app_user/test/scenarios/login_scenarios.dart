import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/features/auth/testing/fake_auth_controller.dart';

import '../goldens/golden_test_helpers.dart' show MockAuthCoordinator;
import 'screenshot_scenario.dart';

class LoginScenarios {
  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'login_page_default',
      page: const LoginPage(),
      overrides: [
        authControllerProvider.overrideWith(FakeAuthController.new),
        authCoordinatorProvider.overrideWithValue(MockAuthCoordinator()),
      ],
    ),
  ];
}
