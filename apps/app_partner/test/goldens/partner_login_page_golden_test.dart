@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart';

void main() {
  // The goldenTest helper registers tests synchronously and is intentionally
  // not awaited inside main().
  // ignore: discarded_futures
  goldenTest(
    'PartnerLoginPage default state',
    fileName: 'partner_login_page_default',
    pumpBeforeTest: (tester) async {
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
            child: PartnerGoldenPageWrapper(
              page: const PartnerLoginPage(),
              overrides: [
                authControllerProvider.overrideWith(_FakeAuthController.new),
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
