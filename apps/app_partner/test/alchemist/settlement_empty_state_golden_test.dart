@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/settlement_empty_state_scenarios.dart';
import '../utils/golden_test_helpers.dart';

void main() {
  for (final scenario in SettlementEmptyStateScenarios.all) {
    // ignore: discarded_futures
    goldenTest(
      scenario.name,
      fileName: scenario.name,
      builder: () => GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(420),
        children: [scenario.toGoldenTestScenario()],
      ),
    );
  }
}
