@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../scenarios/closing_soon_scenarios.dart';
import '../utils/golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  for (final scenario in ClosingSoonScenarios.all) {
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
