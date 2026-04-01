@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import '../utils/partner_golden_test_helpers.dart';

void main() {
  late MockSettlementRepository mockSettlementRepository;
  const partner = Partner(id: 'partner-1', name: '테스트 파트너');
  final now = DateTime(2026, 4, 1, 14);

  SettlementItemDetail makeItem(
    String id, {
    required String status,
    required DateTime createdAt,
    required int netAmount,
  }) {
    return SettlementItemDetail(
      id: id,
      partnerId: partner.id,
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

  setUp(() {
    mockSettlementRepository = MockSettlementRepository();
  });

  goldenTest(
    'SettlementPage dashboard tab',
    fileName: 'settlement_page_dashboard',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () {
      when(
        () => mockSettlementRepository.getSettlementDashboard(
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
        () => mockSettlementRepository.getSettlementItems(
          partnerId: any(named: 'partnerId'),
          status: any(named: 'status'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'dashboard',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const SettlementPage(),
                overrides: [
                  currentPartnerInfoProvider.overrideWith((_) async => partner),
                  settlementRepositoryProvider.overrideWithValue(
                    mockSettlementRepository,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  goldenTest(
    'SettlementPage list tab with data',
    fileName: 'settlement_page_list',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('정산 내역'));
      await tester.pumpAndSettle();
    },
    builder: () {
      when(
        () => mockSettlementRepository.getSettlementDashboard(
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
        () => mockSettlementRepository.getSettlementItems(
          partnerId: any(named: 'partnerId'),
          status: any(named: 'status'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => [
          makeItem(
            'settlement-1',
            status: 'COMPLETED',
            createdAt: now,
            netAmount: 120000,
          ),
          makeItem(
            'settlement-2',
            status: 'PENDING',
            createdAt: now.subtract(const Duration(days: 4)),
            netAmount: 45000,
          ),
        ],
      );

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'list tab',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const SettlementPage(),
                brightness: Brightness.dark,
                overrides: [
                  currentPartnerInfoProvider.overrideWith((_) async => partner),
                  settlementRepositoryProvider.overrideWithValue(
                    mockSettlementRepository,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
