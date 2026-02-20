import 'package:app_user/src/features/explore/logic/explore_coordinator.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/test_utils.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  group('ExploreCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(exploreCoordinatorProvider);

      expect(coordinator, isA<ExploreCoordinator>());
    });

    test('pushEventDetail calls router.push', () {
      final coordinator = ExploreCoordinator(mockRouter);

      coordinator.pushEventDetail('event_123');

      verify(() => mockRouter.push(any(that: contains('event_123')))).called(1);
    });

    test('pushEventCuration calls router.push', () {
      final coordinator = ExploreCoordinator(mockRouter);

      coordinator.pushEventCuration(EventFeedType.nearest);

      verify(() => mockRouter.push(any())).called(1);
    });
  });
}
