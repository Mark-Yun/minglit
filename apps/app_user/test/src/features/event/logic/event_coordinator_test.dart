import 'package:app_user/src/features/event/logic/event_coordinator.dart';
<<<<<<< HEAD
import 'package:app_user/src/routing/app_router.dart';
=======
>>>>>>> origin/dev
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

<<<<<<< HEAD
import '../../../../utils/test_utils.dart';

=======
>>>>>>> origin/dev
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;
<<<<<<< HEAD

  setUp(() {
    mockRouter = MockGoRouter();
=======
  late EventCoordinator coordinator;

  setUp(() {
    mockRouter = MockGoRouter();
    coordinator = EventCoordinator(mockRouter);

>>>>>>> origin/dev
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  group('EventCoordinator', () {
<<<<<<< HEAD
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
=======
    test('pushEventDetail pushes correct route', () {
      coordinator.pushEventDetail('event-123');

      verify(
        () => mockRouter.push('/events/event-123'),
      ).called(1);
    });

    test('pushPartnerDetail pushes correct route', () {
      coordinator.pushPartnerDetail('partner-456');

      verify(
        () => mockRouter.push('/partners/partner-456'),
      ).called(1);
    });

    test('goToEventDetail navigates to correct route', () {
      coordinator.goToEventDetail('event-789');

      verify(
        () => mockRouter.go('/events/event-789'),
      ).called(1);
    });

    test('pushEventCuration pushes curation route', () {
      coordinator.pushEventCuration(EventFeedType.newArrivals);

      verify(
        () => mockRouter.push('/curation'),
      ).called(1);
    });

    test('pushEventCuration with non-default type includes query param', () {
      coordinator.pushEventCuration(EventFeedType.nearest);

      verify(
        () => mockRouter.push(any(that: contains('/curation'))),
      ).called(1);
    });

    test('goToApplicationWizard pushes apply route', () {
      coordinator.goToApplicationWizard('event-abc');

      verify(
        () => mockRouter.push('/events/event-abc/apply'),
      ).called(1);
    });

    test('goToApplicationWizard with ticketId includes query param', () {
      coordinator.goToApplicationWizard('event-abc', ticketId: 'ticket-1');

      verify(
        () => mockRouter.push('/events/event-abc/apply?ticket-id=ticket-1'),
>>>>>>> origin/dev
      ).called(1);
    });
  });
}
