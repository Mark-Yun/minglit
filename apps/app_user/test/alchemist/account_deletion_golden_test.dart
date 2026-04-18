@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenarios/account_deletion_scenarios.dart';
import 'golden_test_helpers.dart';

void main() {
  // ---------------------------------------------------------------------------
  // DeletionInfoPage
  // ---------------------------------------------------------------------------

  goldenTest(
    'DeletionInfoPage — no reason',
    fileName: 'deletion_info_no_reason',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: AccountDeletionScenarios.deletionInfoNoReason
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );

  goldenTest(
    'DeletionInfoPage — with reason',
    fileName: 'deletion_info_with_reason',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: AccountDeletionScenarios.deletionInfoWithReason
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );

  // ---------------------------------------------------------------------------
  // DeletionReasonPage
  // ---------------------------------------------------------------------------

  goldenTest(
    'DeletionReasonPage — initial state',
    fileName: 'deletion_reason_initial',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: AccountDeletionScenarios.deletionReasonInitial
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );

  // ---------------------------------------------------------------------------
  // DeletionVerifyPage
  // ---------------------------------------------------------------------------

  goldenTest(
    'DeletionVerifyPage — social user',
    fileName: 'deletion_verify_social',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: AccountDeletionScenarios.deletionVerifySocial
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );

  goldenTest(
    'DeletionVerifyPage — password user',
    fileName: 'deletion_verify_password',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: AccountDeletionScenarios.deletionVerifyPassword
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );

  // ---------------------------------------------------------------------------
  // DeletionCompletePage
  // ---------------------------------------------------------------------------

  goldenTest(
    'DeletionCompletePage',
    fileName: 'deletion_complete',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: AccountDeletionScenarios.deletionComplete
          .map((s) => s.toGoldenTestScenario())
          .toList(),
    ),
  );
}
