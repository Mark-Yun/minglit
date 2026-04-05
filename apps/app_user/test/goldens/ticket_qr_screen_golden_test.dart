@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/ticket_qr_scenarios.dart';
import 'golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initGoldenDeps();
  });

  for (final scenario in TicketQRScenarios.all) {
    // ignore: discarded_futures
    // Fix #574: Ticket QR viewer has a repeating scan-line animation, so
    // `pumpAndSettle()` would not converge for golden captures.
    goldenTest(
      scenario.name,
      fileName: scenario.name,
      pumpBeforeTest: (tester) async =>
          tester.pump(const Duration(milliseconds: 300)),
      builder: () => GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [scenario.toGoldenTestScenario()],
      ),
    );
  }
}
