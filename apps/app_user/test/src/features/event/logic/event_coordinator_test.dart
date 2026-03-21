import 'package:app_user/src/features/event/logic/event_coordinator.dart';
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
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  group('EventCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(eventCoordinatorProvider);

      expect(coordinator, isA<EventCoordinator>());
    });

    test('pushEventDetail calls router.push with event ID', () {
      EventCoordinator(mockRouter).pushEventDetail('event_123');

      verify(
        () => mockRouter.push(any(that: contains('event_123'))),
      ).called(1);
    });

    test('pushPartnerDetail calls router.push with partner ID', () {
      EventCoordinator(mockRouter).pushPartnerDetail('partner_456');

      verify(
        () => mockRouter.push(any(that: contains('partner_456'))),
      ).called(1);
    });

    test('goToEventDetail calls router.go with event ID', () {
      EventCoordinator(mockRouter).goToEventDetail('event_789');

      verify(
        () => mockRouter.go(any(that: contains('event_789'))),
      ).called(1);
    });

    test('pushEventCuration calls router.push', () {
      EventCoordinator(mockRouter).pushEventCuration(EventFeedType.newArrivals);

      verify(() => mockRouter.push(any())).called(1);
    });

    test('goToApplicationWizard calls router.push with event ID', () {
      EventCoordinator(mockRouter).goToApplicationWizard('event_abc');

      verify(
        () => mockRouter.push(any(that: contains('event_abc'))),
      ).called(1);
    });
  });
}
