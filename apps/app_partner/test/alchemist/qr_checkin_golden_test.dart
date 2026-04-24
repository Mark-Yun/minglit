@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/golden_test_helpers.dart';
import 'scenarios/qr_checkin_scenarios.dart';

void main() {
  for (final scenario in QrCheckinScenarios.all) {
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
