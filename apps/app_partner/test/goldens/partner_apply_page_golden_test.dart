@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/partner_apply_scenarios.dart';
import '../utils/golden_test_helpers.dart';

void main() {
  // ignore: discarded_futures, goldenTest registers the case during main().
  goldenTest(
    'PartnerApplyPage wizard steps',
    fileName: 'partner_apply_page_steps',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: PartnerApplyScenarios.all
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );
}
