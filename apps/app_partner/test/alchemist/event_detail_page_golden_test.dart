@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../scenarios/partner_event_detail_scenarios.dart';
import '../utils/golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  goldenTest(
    'Partner EventDetailPage operation tab',
    fileName: 'partner_event_detail_page_operation',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        PartnerEventDetailScenarios.all[0].toGoldenTestScenario(),
      ],
    ),
  );

  goldenTest(
    'Partner EventDetailPage applications tab',
    fileName: 'partner_event_detail_page_applications',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('참가 신청'));
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        PartnerEventDetailScenarios.all[1].toGoldenTestScenario(),
      ],
    ),
  );
}
