import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:app_partner/src/features/party/list/party_with_stats.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

class PartyListScenarios {
  static final _baseTime = DateTime(2026, 5, 10);
  static final _futureTime = DateTime(2026, 5, 17, 19, 0);
  static final _futureTime2 = DateTime(2026, 5, 20, 14, 0);

  static List<PartyWithStats> get _entries => [
    PartyWithStats(
      party: Party(
        id: 'party1',
        partnerId: 'p1',
        title: '금요 밍글 파티',
        createdAt: _baseTime,
        updatedAt: _baseTime,
      ),
      completedCount: 5,
      upcomingCount: 2,
      nextEvent: Event(
        id: 'ev1',
        partyId: 'party1',
        startTime: _futureTime,
        endTime: _futureTime.add(const Duration(hours: 3)),
        createdAt: _baseTime,
        updatedAt: _baseTime,
        maxParticipants: 20,
        currentParticipants: 12,
        status: 'scheduled',
      ),
    ),
    PartyWithStats(
      party: Party(
        id: 'party2',
        partnerId: 'p1',
        title: '주말 브런치 모임',
        createdAt: _baseTime,
        updatedAt: _baseTime,
      ),
      completedCount: 3,
      upcomingCount: 0,
    ),
    PartyWithStats(
      party: Party(
        id: 'party3',
        partnerId: 'p1',
        title: '평일 네트워킹',
        createdAt: _baseTime,
        updatedAt: _baseTime,
      ),
      completedCount: 0,
      upcomingCount: 1,
      nextEvent: Event(
        id: 'ev2',
        partyId: 'party3',
        startTime: _futureTime2,
        endTime: _futureTime2.add(const Duration(hours: 2)),
        createdAt: _baseTime,
        updatedAt: _baseTime,
        maxParticipants: 15,
        currentParticipants: 0,
        status: 'scheduled',
      ),
    ),
  ];

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'party_list_page_empty',
      page: const PartyListPage(),
      overrides: [
        partyListProvider.overrideWith((_) async => <PartyWithStats>[]),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'party_list_page_with_data',
      page: const PartyListPage(),
      overrides: [
        partyListProvider.overrideWith((_) async => _entries),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'party_list_page_empty_dark',
      page: const PartyListPage(),
      brightness: Brightness.dark,
      overrides: [
        partyListProvider.overrideWith((_) async => <PartyWithStats>[]),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'party_list_page_with_data_dark',
      page: const PartyListPage(),
      brightness: Brightness.dark,
      overrides: [
        partyListProvider.overrideWith((_) async => _entries),
      ],
    ),
  ];
}
