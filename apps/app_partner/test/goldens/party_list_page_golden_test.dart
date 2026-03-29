@Tags(['golden'])
library;

import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart';

void main() {
  final baseTime = DateTime(2026, 5, 10);

  goldenTest(
    'PartyListPage empty state',
    fileName: 'party_list_page_empty',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/party_list_page_empty.render.txt').writeAsStringSync(dump);
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'empty state',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const PartyListPage(),
              overrides: [
                partyListProvider.overrideWith((_) async => <Party>[]),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'PartyListPage with parties',
    fileName: 'party_list_page_with_data',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/party_list_page_with_data.render.txt').writeAsStringSync(dump);
    },
    builder: () {
      final parties = [
        Party(
          id: 'party1',
          partnerId: 'p1',
          title: '금요 밍글 파티',
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
        Party(
          id: 'party2',
          partnerId: 'p1',
          title: '주말 브런치 모임',
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
        Party(
          id: 'party3',
          partnerId: 'p1',
          title: '평일 네트워킹',
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
      ];

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'with parties',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const PartyListPage(),
                overrides: [
                  partyListProvider.overrideWith((_) async => parties),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  goldenTest(
    'PartyListPage empty state (dark)',
    fileName: 'party_list_page_empty_dark',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/party_list_page_empty_dark.render.txt').writeAsStringSync(dump);
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'empty state (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const PartyListPage(),
              brightness: Brightness.dark,
              overrides: [
                partyListProvider.overrideWith((_) async => <Party>[]),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'PartyListPage with parties (dark)',
    fileName: 'party_list_page_with_data_dark',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/party_list_page_with_data_dark.render.txt').writeAsStringSync(dump);
    },
    builder: () {
      final parties = [
        Party(
          id: 'party1',
          partnerId: 'p1',
          title: '금요 밍글 파티',
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
        Party(
          id: 'party2',
          partnerId: 'p1',
          title: '주말 브런치 모임',
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
        Party(
          id: 'party3',
          partnerId: 'p1',
          title: '평일 네트워킹',
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
      ];

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'with parties (dark)',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const PartyListPage(),
                brightness: Brightness.dark,
                overrides: [
                  partyListProvider.overrideWith((_) async => parties),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
