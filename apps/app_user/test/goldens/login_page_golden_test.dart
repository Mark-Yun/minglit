@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/features/auth/testing/fake_auth_controller.dart';

import 'golden_test_helpers.dart';

void main() {
  // The goldenTest helper registers tests synchronously and is intentionally
  // not awaited inside main().
  // ignore: discarded_futures
  goldenTest(
    'LoginPage default state',
    fileName: 'login_page_default',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pump(const Duration(milliseconds: 200));
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'default',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const LoginPage(),
              overrides: [
                authControllerProvider.overrideWith(FakeAuthController.new),
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
}
