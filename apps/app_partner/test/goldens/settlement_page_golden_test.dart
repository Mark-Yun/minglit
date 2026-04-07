@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/settlement_scenarios.dart';
import '../utils/golden_test_helpers.dart';

void main() {
  goldenTest(
    'SettlementPage dashboard tab',
    fileName: 'settlement_page_dashboard',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        SettlementScenarios.all[0].toGoldenTestScenario(),
      ],
    ),
  );

  goldenTest(
    'SettlementPage list tab with data',
    fileName: 'settlement_page_list',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('정산 내역'));
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        SettlementScenarios.all[1].toGoldenTestScenario(),
      ],
    ),
  );
}
