@Tags(['golden'])
library;

import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart';

void main() {
  group('PartyListPage golden', () {
    final baseTime = DateTime(2026, 5, 10);

    testWidgets('empty state', (tester) async {
      await expectPageGolden(
        tester,
        page: const PartyListPage(),
        goldenFileName: 'goldens/party_list_page_empty.png',
        overrides: [
          partyListProvider.overrideWith((_) async => <Party>[]),
        ],
      );
    });

    testWidgets('with parties', (tester) async {
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

      await expectPageGolden(
        tester,
        page: const PartyListPage(),
        goldenFileName: 'goldens/party_list_page_with_data.png',
        overrides: [
          partyListProvider.overrideWith((_) async => parties),
        ],
      );
    });

    testWidgets('empty state (dark)', (tester) async {
      await expectPageGolden(
        tester,
        page: const PartyListPage(),
        goldenFileName: 'goldens/party_list_page_empty_dark.png',
        overrides: [
          partyListProvider.overrideWith((_) async => <Party>[]),
        ],
        brightness: Brightness.dark,
      );
    });

    testWidgets('with parties (dark)', (tester) async {
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

      await expectPageGolden(
        tester,
        page: const PartyListPage(),
        goldenFileName: 'goldens/party_list_page_with_data_dark.png',
        overrides: [
          partyListProvider.overrideWith((_) async => parties),
        ],
        brightness: Brightness.dark,
      );
    });
  });
}
