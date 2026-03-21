import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/features/settlement/settlement_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

/// Waits until SettlementController.status transitions out of loading.
Future<void> waitForSettlement(ProviderContainer container) async {
  final completer = Completer<void>();
  final sub = container.listen(settlementControllerProvider, (prev, next) {
    if (next.status is! AsyncLoading && !completer.isCompleted) {
      completer.complete();
    }
  });
  // Check if already resolved
  final current = container.read(settlementControllerProvider);
  if (current.status is! AsyncLoading) {
    sub.close();
    return;
  }
  await completer.future;
  sub.close();
}

void main() {
  late MockPartnerRepository mockPartnerRepo;
  late Partner fakePartner;

  setUp(() {
    mockPartnerRepo = MockPartnerRepository();
    fakePartner = const Partner(id: 'partner-1', name: 'Test Partner');
  });

  ProviderContainer makeContainer({
    Partner? partner,
    bool nullPartner = false,
    Map<String, dynamic>? revenueStats,
    List<Map<String, dynamic>>? monthlyRevenue,
    List<Map<String, dynamic>>? settlements,
    Exception? error,
  }) {
    final resolvedPartner = nullPartner ? null : (partner ?? fakePartner);

    if (error != null) {
      when(
        () => mockPartnerRepo.getPartnerRevenueStats(any()),
      ).thenThrow(error);
    } else {
      when(() => mockPartnerRepo.getPartnerRevenueStats(any())).thenAnswer(
        (_) async =>
            revenueStats ??
            {'total_sales': 100000, 'total_refunds': 5000, 'net_amount': 95000},
      );
      when(() => mockPartnerRepo.getPartnerMonthlyRevenue(any())).thenAnswer(
        (_) async =>
            monthlyRevenue ??
            [
              {
                'month': '2026-01-01',
                'total_sales': 50000,
                'total_refunds': 2000,
                'net_amount': 48000,
              },
            ],
      );
      when(() => mockPartnerRepo.getPartnerSettlements(any())).thenAnswer(
        (_) async =>
            settlements ??
            [
              {
                'id': 'settle-1',
                'event_id': 'evt-1',
                'event_title': 'Test Event',
                'event_date': '2026-01-15',
                'total_sales': 50000,
                'total_refunds': 2000,
                'pg_fee': 500,
                'platform_fee': 1000,
                'vat': 100,
                'net_amount': 46400,
                'status': 'COMPLETED',
              },
            ],
      );
    }

    return createContainer(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
        currentPartnerInfoProvider.overrideWith(
          (ref) async => resolvedPartner,
        ),
      ],
    );
  }

  group('SettlementController', () {
    test('initial state is loading then resolves to data', () async {
      final container = makeContainer();
      final sub = container.listen(
        settlementControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final state = container.read(settlementControllerProvider);
      expect(state.status, isA<AsyncLoading<void>>());
      expect(state.settlements, isEmpty);
      expect(state.monthlyRevenue, isEmpty);

      // Let the auto-triggered loadSettlementData complete
      await waitForSettlement(container);

      final resolved = container.read(settlementControllerProvider);
      expect(resolved.status, isA<AsyncData<void>>());
    });

    test('loadSettlementData success populates all fields', () async {
      final container = makeContainer();
      final sub = container.listen(
        settlementControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementControllerProvider);
      await waitForSettlement(container);

      final state = container.read(settlementControllerProvider);
      expect(state.status, isA<AsyncData<void>>());
      expect(state.revenueSummary.totalSales, 100000);
      expect(state.revenueSummary.totalRefunds, 5000);
      expect(state.revenueSummary.netAmount, 95000);
      expect(state.monthlyRevenue.length, 1);
      expect(state.monthlyRevenue.first.totalSales, 50000);
      expect(state.settlements.length, 1);
      expect(state.settlements.first.id, 'settle-1');
      expect(state.settlements.first.status, 'completed');
    });

    test(
      'loadSettlementData with null partner returns early with data status',
      () async {
        final container = makeContainer(nullPartner: true);
        final sub = container.listen(
          settlementControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        container.read(settlementControllerProvider);
        await waitForSettlement(container);

        final state = container.read(settlementControllerProvider);
        expect(state.status, isA<AsyncData<void>>());
        expect(state.settlements, isEmpty);
        expect(state.monthlyRevenue, isEmpty);
        verifyNever(() => mockPartnerRepo.getPartnerRevenueStats(any()));
      },
    );

    test('loadSettlementData error sets error status', () async {
      final container = makeContainer(error: Exception('network error'));
      final sub = container.listen(
        settlementControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementControllerProvider);
      await waitForSettlement(container);

      final state = container.read(settlementControllerProvider);
      expect(state.status, isA<AsyncError<void>>());
      expect(state.settlements, isEmpty);
    });

    test('loadSettlementData with empty data works', () async {
      final container = makeContainer(
        revenueStats: {
          'total_sales': 0,
          'total_refunds': 0,
          'net_amount': 0,
        },
        monthlyRevenue: [],
        settlements: [],
      );
      final sub = container.listen(
        settlementControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementControllerProvider);
      await waitForSettlement(container);

      final state = container.read(settlementControllerProvider);
      expect(state.status, isA<AsyncData<void>>());
      expect(state.revenueSummary.totalSales, 0);
      expect(state.monthlyRevenue, isEmpty);
      expect(state.settlements, isEmpty);
    });

    test('loadSettlementData calls repo with correct partnerId', () async {
      final container = makeContainer();
      final sub = container.listen(
        settlementControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementControllerProvider);
      await waitForSettlement(container);

      verify(
        () => mockPartnerRepo.getPartnerRevenueStats('partner-1'),
      ).called(1);
      verify(
        () => mockPartnerRepo.getPartnerMonthlyRevenue('partner-1'),
      ).called(1);
      verify(
        () => mockPartnerRepo.getPartnerSettlements('partner-1'),
      ).called(1);
    });
  });
}
