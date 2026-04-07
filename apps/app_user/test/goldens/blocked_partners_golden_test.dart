@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/blocked_partners_scenarios.dart';
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
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: BlockedPartnersScenarios.emptyScenarios
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
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
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: BlockedPartnersScenarios.withDataScenarios
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );
}
