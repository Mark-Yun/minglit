@Tags(['golden'])
library;

import 'dart:io';

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  const loggedInUser = User(
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

  goldenTest(
    'MyPage logged out state',
    fileName: 'my_page_logged_out',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/my_page_logged_out.render.txt').writeAsStringSync(dump);
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'logged out',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const MyPage(),
              overrides: [
                authCoordinatorProvider.overrideWithValue(
                  MockAuthCoordinator(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'MyPage logged in state',
    fileName: 'my_page_logged_in',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/my_page_logged_in.render.txt').writeAsStringSync(dump);
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'logged in',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const MyPage(),
              currentUser: loggedInUser,
              overrides: [
                authCoordinatorProvider.overrideWithValue(
                  MockAuthCoordinator(),
                ),
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

  goldenTest(
    'MyPage logged out state (dark)',
    fileName: 'my_page_logged_out_dark',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/my_page_logged_out_dark.render.txt').writeAsStringSync(dump);
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'logged out (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const MyPage(),
              brightness: Brightness.dark,
              overrides: [
                authCoordinatorProvider.overrideWithValue(
                  MockAuthCoordinator(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'MyPage logged in state (dark)',
    fileName: 'my_page_logged_in_dark',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/my_page_logged_in_dark.render.txt').writeAsStringSync(dump);
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'logged in (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const MyPage(),
              currentUser: loggedInUser,
              brightness: Brightness.dark,
              overrides: [
                authCoordinatorProvider.overrideWithValue(
                  MockAuthCoordinator(),
                ),
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

class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}
