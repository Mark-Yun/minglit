@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/payment_scenarios.dart';
import 'golden_test_helpers.dart';

void main() {
  // Fix #574: 골든 시나리오 간 repository stub이 섞이지 않도록 매번 새 mock을 사용한다.

  goldenTest(
    'PurchaseHistoryPage states',
    fileName: 'purchase_history_page_states',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: PaymentScenarios.purchaseHistoryScenarios
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );

  goldenTest(
    'PaymentSuccessScreen states',
    fileName: 'payment_success_screen_states',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: PaymentScenarios.paymentSuccessScenarios
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );
}
