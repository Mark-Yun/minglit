@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../scenarios/party_create_wizard_scenarios.dart';
import '../utils/golden_test_helpers.dart';

void main() {
  setUpAll(() {
    kakao.AuthRepository.initialize(appKey: 'test-key');
  });

  // goldenTest registers scenarios synchronously during main().
  // ignore: discarded_futures
  goldenTest(
    'PartyCreateWizardPage key steps',
    fileName: 'party_create_wizard_page_key_steps',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: PartyCreateWizardScenarios.all
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );
}
