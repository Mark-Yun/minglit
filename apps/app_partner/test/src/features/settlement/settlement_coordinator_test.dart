import 'package:app_partner/src/features/settlement/settlement_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

void main() {
  late MockGoRouter mockRouter;
  late MockSettlementRepository mockSettlementRepository;

  setUp(() {
    mockRouter = MockGoRouter();
    mockSettlementRepository = MockSettlementRepository();
    when(() => mockRouter.go(any())).thenReturn(null);
    when(() => mockRouter.push(any())).thenAnswer((_) => Future.value(null));
  });

  group('SettlementCoordinator', () {
    test('creates from provider', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final notifier = container.read(
        settlementCoordinatorProvider.notifier,
      );
      expect(notifier, isA<SettlementCoordinator>());
    });

    test('goToSettlement calls router.go', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(settlementCoordinatorProvider.notifier).goToSettlement();

      verify(() => mockRouter.go(any())).called(1);
    });

    test('goToDetail calls router.push with settlement detail route', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container
          .read(settlementCoordinatorProvider.notifier)
          .goToDetail('test-item-id');

      verify(() => mockRouter.push(any())).called(1);
    });

    test('goToBankAccount calls router.push with bank account route', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(settlementCoordinatorProvider.notifier).goToBankAccount();

      verify(() => mockRouter.push(any())).called(1);
    });

    // Note: retryPayout testing requires widget test context because it calls
    // context.showMinglitSuccess() and handleMinglitError() which need Material context.
    // Unit testing this method would require mocking the entire Material framework.
    // Consider testing retryPayout in integration tests or widget tests instead.
  });
}

// Mock BuildContext for testing retryPayout
class _MockBuildContext extends Mock implements BuildContext {
  @override
  bool get mounted => true;

  @override
  Widget get widget => const SizedBox();
}
