// Fix #1103: settlement 도메인 테스트 보강
//
// Tests for SettlementCoordinator.retryPayout using a full Material widget
// environment, because the method calls context.showMinglitSuccess() and
// handleMinglitError() which require a BuildContext with Scaffold/Material
// ancestry.

import 'package:app_partner/src/features/settlement/settlement_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

// ---------------------------------------------------------------------------
// A minimal widget that can call retryPayout on button tap
// ---------------------------------------------------------------------------
class _RetryTestWidget extends ConsumerWidget {
  const _RetryTestWidget({
    required this.payoutId,
    required this.partnerId,
  });

  final String payoutId;
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await ref
            .read(settlementCoordinatorProvider.notifier)
            .retryPayout(
              context,
              payoutId: payoutId,
              partnerId: partnerId,
            );
      },
      child: const Text('Retry'),
    );
  }
}

void main() {
  late MockSettlementRepository mockSettlementRepo;
  late MockGoRouter mockRouter;

  setUp(() {
    mockSettlementRepo = MockSettlementRepository();
    mockRouter = MockGoRouter();
    when(() => mockRouter.go(any())).thenReturn(null);
    when(() => mockRouter.push(any())).thenAnswer((_) => Future.value());
  });

  group('SettlementCoordinator.retryPayout', () {
    testWidgets('calls settlementRepository.retryPayout with correct args', (
      tester,
    ) async {
      when(
        () => mockSettlementRepo.retryPayout(
          payoutId: any(named: 'payoutId'),
          partnerId: any(named: 'partnerId'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementRepositoryProvider.overrideWithValue(mockSettlementRepo),
            goRouterProvider.overrideWithValue(mockRouter),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: _RetryTestWidget(
                payoutId: 'payout-1',
                partnerId: 'partner-1',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      verify(
        () => mockSettlementRepo.retryPayout(
          payoutId: 'payout-1',
          partnerId: 'partner-1',
        ),
      ).called(1);
    });

    testWidgets('on success shows success snackbar', (tester) async {
      when(
        () => mockSettlementRepo.retryPayout(
          payoutId: any(named: 'payoutId'),
          partnerId: any(named: 'partnerId'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementRepositoryProvider.overrideWithValue(mockSettlementRepo),
            goRouterProvider.overrideWithValue(mockRouter),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: _RetryTestWidget(
                payoutId: 'payout-1',
                partnerId: 'partner-1',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // showMinglitSuccess shows a SnackBar — verify it appeared
      expect(find.text('재지급 요청이 완료되었습니다.'), findsOneWidget);
    });

    testWidgets('on failure does not crash the widget tree', (tester) async {
      when(
        () => mockSettlementRepo.retryPayout(
          payoutId: any(named: 'payoutId'),
          partnerId: any(named: 'partnerId'),
        ),
      ).thenThrow(Exception('network error'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementRepositoryProvider.overrideWithValue(mockSettlementRepo),
            goRouterProvider.overrideWithValue(mockRouter),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: _RetryTestWidget(
                payoutId: 'payout-1',
                partnerId: 'partner-1',
              ),
            ),
          ),
        ),
      );

      // Should not throw
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Widget tree should still be visible
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('on failure calls retryPayout exactly once', (tester) async {
      when(
        () => mockSettlementRepo.retryPayout(
          payoutId: any(named: 'payoutId'),
          partnerId: any(named: 'partnerId'),
        ),
      ).thenThrow(Exception('server error'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementRepositoryProvider.overrideWithValue(mockSettlementRepo),
            goRouterProvider.overrideWithValue(mockRouter),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: _RetryTestWidget(
                payoutId: 'payout-1',
                partnerId: 'partner-1',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      verify(
        () => mockSettlementRepo.retryPayout(
          payoutId: 'payout-1',
          partnerId: 'partner-1',
        ),
      ).called(1);
    });
  });
}
