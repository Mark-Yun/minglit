import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'partner_screenshot_scenario.dart';

class SettlementScenarios {
  static const _partner = Partner(id: 'partner-1', name: '테스트 파트너');
  static final _now = DateTime(2026, 4, 1, 14);

  static SettlementItemDetail _makeItem(
    String id, {
    required String status,
    required DateTime createdAt,
    required int netAmount,
  }) {
    return SettlementItemDetail(
      id: id,
      partnerId: _partner.id,
      status: status,
      grossAmount: netAmount + 800,
      platformFeeAmount: 500,
      pgFeeAmount: 200,
      vatAmount: 100,
      netAmount: netAmount,
      currency: 'KRW',
      createdAt: createdAt,
      updatedAt: createdAt,
      retryable: false,
      retryCount: 0,
      histories: const [],
      adjustments: const [],
    );
  }

  static List<dynamic> _dashboardOverrides() {
    final mockRepo = MockSettlementRepository();
    when(
      () => mockRepo.getSettlementDashboard(
        partnerId: any(named: 'partnerId'),
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'completed_gross_total': 420000,
        'completed_net_total': 360000,
        'pending_gross_total': 60000,
        'status_counts': <String, dynamic>{
          'PENDING': 2,
          'READY': 1,
          'PROCESSING': 1,
          'COMPLETED': 5,
          'FAILED': 0,
          'HOLD': 0,
          'CANCELED': 0,
        },
      },
    );
    when(
      () => mockRepo.getSettlementItems(
        partnerId: any(named: 'partnerId'),
        status: any(named: 'status'),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);
    return [
      currentPartnerInfoProvider.overrideWith((_) async => _partner),
      settlementRepositoryProvider.overrideWithValue(mockRepo),
    ];
  }

  static List<dynamic> _listOverrides() {
    final mockRepo = MockSettlementRepository();
    when(
      () => mockRepo.getSettlementDashboard(
        partnerId: any(named: 'partnerId'),
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'status_counts': <String, dynamic>{},
      },
    );
    when(
      () => mockRepo.getSettlementItems(
        partnerId: any(named: 'partnerId'),
        status: any(named: 'status'),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => [
        _makeItem(
          'settlement-1',
          status: 'COMPLETED',
          createdAt: _now,
          netAmount: 120000,
        ),
        _makeItem(
          'settlement-2',
          status: 'PENDING',
          createdAt: _now.subtract(const Duration(days: 4)),
          netAmount: 45000,
        ),
      ],
    );
    return [
      currentPartnerInfoProvider.overrideWith((_) async => _partner),
      settlementRepositoryProvider.overrideWithValue(mockRepo),
    ];
  }

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'settlement_page_dashboard',
      page: const SettlementPage(),
      overrides: _dashboardOverrides(),
    ),
    PartnerScreenshotScenario(
      name: 'settlement_page_list',
      page: const SettlementPage(),
      brightness: Brightness.dark,
      overrides: _listOverrides(),
    ),
  ];
}
