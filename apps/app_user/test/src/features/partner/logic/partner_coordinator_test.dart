import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/test_utils.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;
  late PartnerCoordinator coordinator;

  setUp(() {
    mockRouter = MockGoRouter();
    coordinator = PartnerCoordinator(mockRouter);

    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  group('PartnerCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final result = container.read(partnerCoordinatorProvider);

      expect(result, isA<PartnerCoordinator>());
    });

    test('pushEventDetail pushes correct route', () {
      coordinator.pushEventDetail('event-123');

      verify(
        () => mockRouter.push(
          const EventDetailRoute(eventId: 'event-123').location,
        ),
      ).called(1);
    });

    test('pushPartnerEvents pushes correct route', () {
      coordinator.pushPartnerEvents(
        partnerId: 'partner-456',
        partnerName: 'Test Partner',
      );

      verify(
        () => mockRouter.push(
          const PartnerEventsRoute(
            partnerId: 'partner-456',
            partnerName: 'Test Partner',
          ).location,
        ),
      ).called(1);
    });
  });
}
