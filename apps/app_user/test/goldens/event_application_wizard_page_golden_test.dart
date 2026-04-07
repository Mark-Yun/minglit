@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/event_application_scenarios.dart';
import 'golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initGoldenDeps();
  });

  // ignore: discarded_futures, goldenTest registers the case during main().
  goldenTest(
    'EventApplicationWizardPage steps',
    fileName: 'event_application_wizard_page_steps',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: EventApplicationScenarios.all
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );
}
