import 'dart:async';

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../goldens/golden_test_helpers.dart'
    show MockAuthCoordinator, MockHomeCoordinator;
import 'screenshot_scenario.dart';

const _loggedInUser = User(
  id: 'u1',
  appMetadata: {},
  userMetadata: {
    'full_name': '홍길동',
    'avatar_url': null,
  },
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00.000Z',
  email: 'test@minglit.com',
);

class MyPageScenarios {
  static List<dynamic> _loggedOutOverrides() => [
    authCoordinatorProvider.overrideWithValue(MockAuthCoordinator()),
  ];

  static List<dynamic> _loggedInOverrides() => [
    authCoordinatorProvider.overrideWithValue(MockAuthCoordinator()),
    homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator()),
    authControllerProvider.overrideWith(FakeAuthController.new),
  ];

  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'my_page_logged_out',
      page: const MyPage(),
      overrides: _loggedOutOverrides(),
    ),
    ScreenshotScenario(
      name: 'my_page_logged_in',
      page: const MyPage(),
      currentUser: _loggedInUser,
      overrides: _loggedInOverrides(),
    ),
    ScreenshotScenario(
      name: 'my_page_logged_out_dark',
      page: const MyPage(),
      brightness: Brightness.dark,
      overrides: _loggedOutOverrides(),
    ),
    ScreenshotScenario(
      name: 'my_page_logged_in_dark',
      page: const MyPage(),
      currentUser: _loggedInUser,
      brightness: Brightness.dark,
      overrides: _loggedInOverrides(),
    ),
  ];
}

class FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}
