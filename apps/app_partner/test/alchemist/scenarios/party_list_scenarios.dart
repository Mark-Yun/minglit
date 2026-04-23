import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

class PartyListScenarios {
  static final _baseTime = DateTime(2026, 5, 10);

  static List<Party> get _parties => [
    Party(
      id: 'party1',
      partnerId: 'p1',
      title: '금요 밍글 파티',
      createdAt: _baseTime,
      updatedAt: _baseTime,
    ),
    Party(
      id: 'party2',
      partnerId: 'p1',
      title: '주말 브런치 모임',
      createdAt: _baseTime,
      updatedAt: _baseTime,
    ),
    Party(
      id: 'party3',
      partnerId: 'p1',
      title: '평일 네트워킹',
      createdAt: _baseTime,
      updatedAt: _baseTime,
    ),
  ];

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'party_list_page_empty',
      page: const PartyListPage(),
      overrides: [
        partyListProvider.overrideWith((_) async => <Party>[]),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'party_list_page_with_data',
      page: const PartyListPage(),
      overrides: [
        partyListProvider.overrideWith((_) async => _parties),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'party_list_page_empty_dark',
      page: const PartyListPage(),
      brightness: Brightness.dark,
      overrides: [
        partyListProvider.overrideWith((_) async => <Party>[]),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'party_list_page_with_data_dark',
      page: const PartyListPage(),
      brightness: Brightness.dark,
      overrides: [
        partyListProvider.overrideWith((_) async => _parties),
      ],
    ),
  ];
}
