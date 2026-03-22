import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
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

  group('AuthCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(authCoordinatorProvider);

      expect(coordinator, isA<AuthCoordinator>());
    });

    test('pushLogin calls router.push with login path', () {
      AuthCoordinator(mockRouter).pushLogin();

      verify(() => mockRouter.push(any(that: contains('/login')))).called(1);
    });

    test('pushLogin with from parameter includes from in path', () {
      AuthCoordinator(mockRouter).pushLogin(from: '/home');

      verify(() => mockRouter.push(any(that: contains('/login')))).called(1);
    });

    test('goToLogin calls router.go with login path', () {
      AuthCoordinator(mockRouter).goToLogin();

      verify(() => mockRouter.go(any(that: contains('/login')))).called(1);
    });

    test('goToLogin with from parameter calls router.go', () {
      AuthCoordinator(mockRouter).goToLogin(from: '/events');

      verify(() => mockRouter.go(any(that: contains('/login')))).called(1);
    });

    test('goToReturnLocation calls router.go with exact location', () {
      const location = '/events/123';
      AuthCoordinator(mockRouter).goToReturnLocation(location);

      verify(() => mockRouter.go(location)).called(1);
    });
  });
}
