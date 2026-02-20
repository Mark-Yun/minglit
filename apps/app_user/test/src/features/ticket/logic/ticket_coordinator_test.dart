import 'package:app_user/src/features/ticket/logic/ticket_coordinator.dart';
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
  });

  group('TicketCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(ticketCoordinatorProvider);

      expect(coordinator, isA<TicketCoordinator>());
    });

    test('pushEventDetail calls router.push with event ID', () {
      final coordinator = TicketCoordinator(mockRouter);

      coordinator.pushEventDetail('event_456');

      verify(() => mockRouter.push(any(that: contains('event_456')))).called(1);
    });
  });
}
