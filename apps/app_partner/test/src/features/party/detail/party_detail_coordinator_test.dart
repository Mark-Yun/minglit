import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.go(any())).thenReturn(null);
    when(() => mockRouter.push(any())).thenAnswer((_) => Future.value());
  });

  group('PartyDetailCoordinator', () {
    test('creates from provider', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(partyDetailCoordinatorProvider);
      expect(coordinator, isA<PartyDetailCoordinator>());
    });

    test('goToEditParty calls router.push with edit route', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(partyDetailCoordinatorProvider).goToEditParty('party-1');

      verify(
        () => mockRouter.push(
          PartyEditRoute(partyId: 'party-1').location,
        ),
      ).called(1);
    });

    test('goToCreateEvent calls router.push with event create route', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(partyDetailCoordinatorProvider).goToCreateEvent('party-1');

      verify(
        () => mockRouter.push(
          EventCreateRoute(partyId: 'party-1').location,
        ),
      ).called(1);
    });

    test('goToEventDetail calls router.go with event detail route', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container
          .read(partyDetailCoordinatorProvider)
          .goToEventDetail('party-1', 'event-1');

      verify(
        () => mockRouter.go(
          EventDetailRoute(partyId: 'party-1', eventId: 'event-1').location,
        ),
      ).called(1);
    });

    test('goToCreateTicket calls router.push with ticket create route', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container
          .read(partyDetailCoordinatorProvider)
          .goToCreateTicket('party-1', 'event-1');

      verify(
        () => mockRouter.push(
          TicketCreateRoute(partyId: 'party-1', eventId: 'event-1').location,
        ),
      ).called(1);
    });
  });
}
