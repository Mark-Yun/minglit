import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  group('PartnerHomeCoordinator', () {
    test('creates from provider', () {
      final container = createContainer(
        overrides: [goRouterProvider.overrideWithValue(mockRouter)],
      );

      final coordinator = container.read(partnerHomeCoordinatorProvider);
      expect(coordinator, isA<PartnerHomeCoordinator>());
    });

    test('pushNotificationCenter calls router.push', () {
      final container = createContainer(
        overrides: [goRouterProvider.overrideWithValue(mockRouter)],
      );

      container.read(partnerHomeCoordinatorProvider).pushNotificationCenter();

      verify(() => mockRouter.push(any())).called(1);
    });

    test('pushApplicationList calls router.push', () {
      final container = createContainer(
        overrides: [goRouterProvider.overrideWithValue(mockRouter)],
      );

      container.read(partnerHomeCoordinatorProvider).pushApplicationList();

      verify(() => mockRouter.push(any())).called(1);
    });

    test('pushLocationGuide calls router.push with location guide route', () {
      // Fix #1269: 홈 장소 가이드 배너가 실제 P-S06 라우트로 이동하는지 검증한다.
      final container = createContainer(
        overrides: [goRouterProvider.overrideWithValue(mockRouter)],
      );

      container.read(partnerHomeCoordinatorProvider).pushLocationGuide();

      verify(
        () => mockRouter.push(any(that: equals('/guide/location'))),
      ).called(1);
    });

    test('goToSettlement calls router.go with settlement route', () {
      final container = createContainer(
        overrides: [goRouterProvider.overrideWithValue(mockRouter)],
      );

      container.read(partnerHomeCoordinatorProvider).goToSettlement();

      verify(() => mockRouter.go(any())).called(1);
      verifyNever(() => mockRouter.push(any()));
    });

    test(
      'pushNotificationCenter and pushApplicationList push different routes',
      () {
        final container = createContainer(
          overrides: [goRouterProvider.overrideWithValue(mockRouter)],
        );
        final coordinator = container.read(partnerHomeCoordinatorProvider);

        coordinator.pushNotificationCenter();
        coordinator.pushApplicationList();

        final captured = verify(() => mockRouter.push(captureAny())).captured;
        expect(captured.length, 2);
        expect(captured[0], isNot(equals(captured[1])));
      },
    );
  });
}
