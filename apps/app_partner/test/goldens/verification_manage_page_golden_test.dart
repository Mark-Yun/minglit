@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/verification_manage_scenarios.dart';
import '../utils/golden_test_helpers.dart';

void main() {
  for (final scenario in VerificationManageScenarios.all) {
    // The goldenTest helper registers tests synchronously and is intentionally
    // not awaited inside main().
    goldenTest(
      scenario.name,
      fileName: scenario.name,
      pumpBeforeTest: (tester) async => tester.pumpAndSettle(),
      builder: () => GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [scenario.toGoldenTestScenario()],
      ),
    );
  }
}
