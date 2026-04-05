@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/my_page_scenarios.dart';
import 'golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initGoldenDeps();
  });

  for (final scenario in MyPageScenarios.all) {
    // ignore: discarded_futures
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
