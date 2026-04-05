@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/event_detail_scenarios.dart';
import 'golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initGoldenDeps();
  });

  // ignore: discarded_futures, goldenTest registers the case during main().
  goldenTest(
    'EventDetailPage admission states',
    fileName: 'event_detail_page_states',
    pumpBeforeTest: (tester) async {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: EventDetailScenarios.all
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );
}
