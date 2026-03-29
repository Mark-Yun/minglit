// Fix #634: PartyCoordinator unit tests
import 'package:app_user/src/features/party/logic/party_coordinator.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/test_utils.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;
  late PartyCoordinator coordinator;

  setUp(() {
    mockRouter = MockGoRouter();
    coordinator = PartyCoordinator(mockRouter);

    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  group('PartyCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final result = container.read(partyCoordinatorProvider);

      expect(result, isA<PartyCoordinator>());
    });

    test('pushEventDetail pushes correct route', () {
      coordinator.pushEventDetail('event-789');

      verify(
        () => mockRouter.push(any(that: contains('/events/event-789'))),
      ).called(1);
    });
  });
}
