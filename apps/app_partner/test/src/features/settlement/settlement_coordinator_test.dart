import 'package:app_partner/src/features/settlement/settlement_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.go(any())).thenReturn(null);
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
  });
}
