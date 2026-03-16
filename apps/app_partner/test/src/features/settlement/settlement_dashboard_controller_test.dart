import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/features/settlement/settlement_dashboard_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

/// Waits for all pending microtasks and async operations to complete.
Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  late MockSettlementRepository mockRepo;
  late Partner fakePartner;

  setUp(() {
    mockRepo = MockSettlementRepository();
    fakePartner = const Partner(id: 'partner-1', name: 'Test Partner');
  });

  ProviderContainer makeContainer({
    Partner? partner,
    bool nullPartner = false,
    Map<String, dynamic>? dashboardData,
    Exception? dashboardError,
  }) {
    final resolvedPartner = nullPartner ? null : (partner ?? fakePartner);

    if (dashboardError != null) {
      when(
        () => mockRepo.getSettlementDashboard(
          partnerId: any(named: 'partnerId'),
          periodStart: any(named: 'periodStart'),
          periodEnd: any(named: 'periodEnd'),
        ),
      ).thenThrow(dashboardError);
    } else {
      when(
        () => mockRepo.getSettlementDashboard(
          partnerId: any(named: 'partnerId'),
          periodStart: any(named: 'periodStart'),
          periodEnd: any(named: 'periodEnd'),
        ),
      ).thenAnswer((_) async => dashboardData ?? {'total_items': 0});
    }

    return createContainer(
      overrides: [
        settlementRepositoryProvider.overrideWithValue(mockRepo),
        currentPartnerInfoProvider.overrideWith(
          (ref) async => resolvedPartner,
        ),
      ],
    );
  }

  group('SettlementDashboardController', () {
    test('initial state has current month as selectedMonth', () async {
      final container = makeContainer();
      // Listen to keep provider alive during async microtask
      final sub = container.listen(
        settlementDashboardControllerProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      final state = container.read(settlementDashboardControllerProvider);
      final now = DateTime.now();
      expect(state.selectedMonth.year, now.year);
      expect(state.selectedMonth.month, now.month);
      expect(state.selectedMonth.day, 1);

      await pump();
    });

    test('initial state has loading status', () async {
      final container = makeContainer();
      final sub = container.listen(
        settlementDashboardControllerProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      final state = container.read(settlementDashboardControllerProvider);
      expect(state.status, isA<AsyncLoading>());

      await pump();
    });

    test('loadDashboard success populates dashboardData', () async {
      final data = {
        'status_counts': {'COMPLETED': 3},
        'completed_net_total': 90000,
        'total_items': 3,
      };
      final container = makeContainer(dashboardData: data);
      final sub = container.listen(
        settlementDashboardControllerProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      // Trigger build
      container.read(settlementDashboardControllerProvider);

      // Wait for microtask + async to complete
      await pump();

      final state = container.read(settlementDashboardControllerProvider);
      expect(state.status, isA<AsyncData>());
      expect(state.dashboardData, equals(data));
    });

    test('loadDashboard error sets error status', () async {
      final error = Exception('network error');
      final container = makeContainer(dashboardError: error);
      final sub = container.listen(
        settlementDashboardControllerProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      container.read(settlementDashboardControllerProvider);
      await pump();

      final state = container.read(settlementDashboardControllerProvider);
      expect(state.status, isA<AsyncError>());
      expect(state.dashboardData, isNull);
    });

    test(
      'loadDashboard with null partner sets data status without loading',
      () async {
        final container = makeContainer(nullPartner: true);
        final sub = container.listen(
          settlementDashboardControllerProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        container.read(settlementDashboardControllerProvider);
        await pump();

        final state = container.read(settlementDashboardControllerProvider);
        expect(state.status, isA<AsyncData>());
        expect(state.dashboardData, isNull);
      },
    );

    test('changeMonth updates selectedMonth and reloads', () async {
      final container = makeContainer();
      final sub = container.listen(
        settlementDashboardControllerProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      container.read(settlementDashboardControllerProvider);
      await pump();

      final now = DateTime.now();
      final expectedMonth = DateTime(now.year, now.month + 1);

      container
          .read(settlementDashboardControllerProvider.notifier)
          .changeMonth(1);

      final stateAfterChange = container.read(
        settlementDashboardControllerProvider,
      );
      expect(stateAfterChange.selectedMonth, equals(expectedMonth));
      expect(stateAfterChange.dashboardData, isNull);

      // Wait for reload
      await pump();

      final stateAfterReload = container.read(
        settlementDashboardControllerProvider,
      );
      expect(stateAfterReload.status, isA<AsyncData>());
    });

    test('changeMonth with negative delta goes to previous month', () async {
      final container = makeContainer();
      final sub = container.listen(
        settlementDashboardControllerProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      container.read(settlementDashboardControllerProvider);
      await pump();

      final now = DateTime.now();
      final expectedMonth = DateTime(now.year, now.month - 1);

      container
          .read(settlementDashboardControllerProvider.notifier)
          .changeMonth(-1);

      final state = container.read(settlementDashboardControllerProvider);
      expect(state.selectedMonth, equals(expectedMonth));

      await pump();
    });
  });
}
