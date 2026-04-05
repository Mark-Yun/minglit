import 'dart:async';

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../goldens/golden_test_helpers.dart'
    show MockAccountDeletionCoordinator, MockHomeCoordinator;
import 'screenshot_scenario.dart';

const _passwordUser = User(
  id: 'u1',
  appMetadata: {'provider': 'email'},
  userMetadata: {'full_name': '홍길동'},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00.000Z',
  email: 'test@minglit.com',
);

const _socialUser = User(
  id: 'u2',
  appMetadata: {'provider': 'google'},
  userMetadata: {'full_name': '홍길동'},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00.000Z',
  email: 'test@gmail.com',
);

class AccountDeletionScenarios {
  // DeletionInfoPage — no reason (light + dark)
  static List<ScreenshotScenario> get deletionInfoNoReason => [
    ScreenshotScenario(
      name: 'deletion_info_no_reason_light',
      page: const DeletionInfoPage(),
      currentUser: _passwordUser,
      overrides: [
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
    ScreenshotScenario(
      name: 'deletion_info_no_reason_dark',
      page: const DeletionInfoPage(),
      currentUser: _passwordUser,
      brightness: Brightness.dark,
      overrides: [
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
  ];

  // DeletionInfoPage — with reason
  static List<ScreenshotScenario> get deletionInfoWithReason => [
    ScreenshotScenario(
      name: 'deletion_info_with_reason_light',
      page: const DeletionInfoPage(reasonCode: 'no_longer_use'),
      currentUser: _passwordUser,
      overrides: [
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
    ScreenshotScenario(
      name: 'deletion_info_with_reason_dark',
      page: const DeletionInfoPage(reasonCode: 'no_longer_use'),
      currentUser: _passwordUser,
      brightness: Brightness.dark,
      overrides: [
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
  ];

  // DeletionReasonPage — initial
  static List<ScreenshotScenario> get deletionReasonInitial => [
    ScreenshotScenario(
      name: 'deletion_reason_initial_light',
      page: const DeletionReasonPage(),
      currentUser: _passwordUser,
      overrides: [
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
    ScreenshotScenario(
      name: 'deletion_reason_initial_dark',
      page: const DeletionReasonPage(),
      currentUser: _passwordUser,
      brightness: Brightness.dark,
      overrides: [
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
  ];

  // DeletionVerifyPage — social user
  static List<ScreenshotScenario> get deletionVerifySocial => [
    ScreenshotScenario(
      name: 'deletion_verify_social_light',
      page: const DeletionVerifyPage(),
      currentUser: _socialUser,
      overrides: [
        accountDeletionControllerProvider.overrideWith(
          FakeAccountDeletionController.new,
        ),
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
    ScreenshotScenario(
      name: 'deletion_verify_social_dark',
      page: const DeletionVerifyPage(),
      currentUser: _socialUser,
      brightness: Brightness.dark,
      overrides: [
        accountDeletionControllerProvider.overrideWith(
          FakeAccountDeletionController.new,
        ),
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
  ];

  // DeletionVerifyPage — password user
  static List<ScreenshotScenario> get deletionVerifyPassword => [
    ScreenshotScenario(
      name: 'deletion_verify_password_light',
      page: const DeletionVerifyPage(),
      currentUser: _passwordUser,
      overrides: [
        accountDeletionControllerProvider.overrideWith(
          FakeAccountDeletionController.new,
        ),
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
    ScreenshotScenario(
      name: 'deletion_verify_password_dark',
      page: const DeletionVerifyPage(),
      currentUser: _passwordUser,
      brightness: Brightness.dark,
      overrides: [
        accountDeletionControllerProvider.overrideWith(
          FakeAccountDeletionController.new,
        ),
        accountDeletionCoordinatorProvider.overrideWithValue(
          MockAccountDeletionCoordinator(),
        ),
      ],
    ),
  ];

  // DeletionCompletePage
  static List<ScreenshotScenario> get deletionComplete => [
    ScreenshotScenario(
      name: 'deletion_complete_light',
      page: const DeletionCompletePage(),
      currentUser: _passwordUser,
      overrides: [
        homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator()),
        authControllerProvider.overrideWith(FakeDeletionAuthController.new),
      ],
    ),
    ScreenshotScenario(
      name: 'deletion_complete_dark',
      page: const DeletionCompletePage(),
      currentUser: _passwordUser,
      brightness: Brightness.dark,
      overrides: [
        homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator()),
        authControllerProvider.overrideWith(FakeDeletionAuthController.new),
      ],
    ),
  ];

  static List<ScreenshotScenario> get all => [
    ...deletionInfoNoReason,
    ...deletionInfoWithReason,
    ...deletionReasonInitial,
    ...deletionVerifySocial,
    ...deletionVerifyPassword,
    ...deletionComplete,
  ];
}

class FakeAccountDeletionController extends AccountDeletionController {
  @override
  FutureOr<DeletionStatus?> build() async => null;
}

class FakeDeletionAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}
