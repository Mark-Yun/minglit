import 'package:app_user/src/features/home/logic/home_coordinator.dart';
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

  group('HomeCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(homeCoordinatorProvider);

      expect(coordinator, isA<HomeCoordinator>());
    });

    test('pushNotificationCenter calls router.push', () {
      HomeCoordinator(mockRouter).pushNotificationCenter();

      verify(
        () => mockRouter.push(any(that: contains('/notifications'))),
      ).called(1);
    });

    test('pushPurchaseHistory calls router.push', () {
      HomeCoordinator(mockRouter).pushPurchaseHistory();

      verify(
        () => mockRouter.push(any(that: contains('purchase-history'))),
      ).called(1);
    });

    test('goToPurchaseHistory calls router.go', () {
      HomeCoordinator(mockRouter).goToPurchaseHistory();

      verify(
        () => mockRouter.go(any(that: contains('purchase-history'))),
      ).called(1);
    });

    test('pushNotificationSettings calls router.push', () {
      HomeCoordinator(mockRouter).pushNotificationSettings();

      verify(
        () => mockRouter.push(any(that: contains('notification-settings'))),
      ).called(1);
    });
  });
}
