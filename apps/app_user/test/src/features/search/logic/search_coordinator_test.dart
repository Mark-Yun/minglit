// Fix #634: SearchCoordinator unit tests
import 'package:app_user/src/features/search/logic/search_coordinator.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/test_utils.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;
  late SearchCoordinator coordinator;

  setUp(() {
    mockRouter = MockGoRouter();
    coordinator = SearchCoordinator(mockRouter);

    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  group('SearchCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final result = container.read(searchCoordinatorProvider);

      expect(result, isA<SearchCoordinator>());
    });

    test('pushEventDetail pushes correct route', () {
      coordinator.pushEventDetail('event-456');

      verify(
        () => mockRouter.push(any(that: contains('/events/event-456'))),
      ).called(1);
    });
  });
}
