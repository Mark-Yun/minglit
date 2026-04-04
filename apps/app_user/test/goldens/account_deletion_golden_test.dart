@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

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

void main() {
  // ---------------------------------------------------------------------------
  // DeletionInfoPage
  // ---------------------------------------------------------------------------

  goldenTest(
    'DeletionInfoPage — no reason',
    fileName: 'deletion_info_no_reason',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'no reason (light)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionInfoPage(),
              currentUser: _passwordUser,
              overrides: [
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'no reason (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionInfoPage(),
              currentUser: _passwordUser,
              brightness: Brightness.dark,
              overrides: [
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'DeletionInfoPage — with reason',
    fileName: 'deletion_info_with_reason',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'with reason (light)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionInfoPage(
                reasonCode: 'no_longer_use',
              ),
              currentUser: _passwordUser,
              overrides: [
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'with reason (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionInfoPage(
                reasonCode: 'no_longer_use',
              ),
              currentUser: _passwordUser,
              brightness: Brightness.dark,
              overrides: [
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // DeletionReasonPage
  // ---------------------------------------------------------------------------

  goldenTest(
    'DeletionReasonPage — initial state',
    fileName: 'deletion_reason_initial',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'initial (light)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionReasonPage(),
              currentUser: _passwordUser,
              overrides: [
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'initial (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionReasonPage(),
              currentUser: _passwordUser,
              brightness: Brightness.dark,
              overrides: [
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // DeletionVerifyPage
  // ---------------------------------------------------------------------------

  goldenTest(
    'DeletionVerifyPage — social user',
    fileName: 'deletion_verify_social',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'social user (light)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionVerifyPage(),
              currentUser: _socialUser,
              overrides: [
                accountDeletionControllerProvider.overrideWith(
                  _FakeAccountDeletionController.new,
                ),
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'social user (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionVerifyPage(),
              currentUser: _socialUser,
              brightness: Brightness.dark,
              overrides: [
                accountDeletionControllerProvider.overrideWith(
                  _FakeAccountDeletionController.new,
                ),
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'DeletionVerifyPage — password user',
    fileName: 'deletion_verify_password',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'password user (light)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionVerifyPage(),
              currentUser: _passwordUser,
              overrides: [
                accountDeletionControllerProvider.overrideWith(
                  _FakeAccountDeletionController.new,
                ),
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'password user (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionVerifyPage(),
              currentUser: _passwordUser,
              brightness: Brightness.dark,
              overrides: [
                accountDeletionControllerProvider.overrideWith(
                  _FakeAccountDeletionController.new,
                ),
                accountDeletionCoordinatorProvider.overrideWithValue(
                  MockAccountDeletionCoordinator(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // DeletionCompletePage
  // ---------------------------------------------------------------------------

  goldenTest(
    'DeletionCompletePage',
    fileName: 'deletion_complete',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'complete (light)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionCompletePage(),
              currentUser: _passwordUser,
              overrides: [
                homeCoordinatorProvider.overrideWithValue(
                  MockHomeCoordinator(),
                ),
                authControllerProvider.overrideWith(
                  _FakeAuthController.new,
                ),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'complete (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const DeletionCompletePage(),
              currentUser: _passwordUser,
              brightness: Brightness.dark,
              overrides: [
                homeCoordinatorProvider.overrideWithValue(
                  MockHomeCoordinator(),
                ),
                authControllerProvider.overrideWith(
                  _FakeAuthController.new,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _FakeAccountDeletionController extends AccountDeletionController {
  @override
  FutureOr<DeletionStatus?> build() async => null;
}

class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}
