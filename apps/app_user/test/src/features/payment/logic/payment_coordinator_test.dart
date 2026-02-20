import 'package:app_user/src/features/payment/logic/payment_coordinator.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/test_utils.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  group('PaymentCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(paymentCoordinatorProvider);

      expect(coordinator, isA<PaymentCoordinator>());
    });

    test('pushPurchaseHistory calls router.push', () {
      final coordinator = PaymentCoordinator(mockRouter);

      coordinator.pushPurchaseHistory();

      verify(() => mockRouter.push(any())).called(1);
    });

    test('goToPurchaseHistory calls router.go', () {
      final coordinator = PaymentCoordinator(mockRouter);

      coordinator.goToPurchaseHistory();

      verify(() => mockRouter.go(any())).called(1);
    });
  });
}
