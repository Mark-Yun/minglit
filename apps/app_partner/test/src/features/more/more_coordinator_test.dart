import 'package:app_partner/src/features/more/more_coordinator.dart';
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
  });

  group('MoreCoordinator', () {
    test('creates from provider', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(moreCoordinatorProvider);
      expect(coordinator, isA<MoreCoordinator>());
    });

    test('pushNotificationSettings calls router.push', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(moreCoordinatorProvider).pushNotificationSettings();

      verify(() => mockRouter.push(any())).called(1);
    });

    test('pushMemberList calls router.push with partnerId in route', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(moreCoordinatorProvider).pushMemberList('partner_abc');

      verify(
        () => mockRouter.push(any(that: contains('partner_abc'))),
      ).called(1);
    });

    test('pushVerificationManage calls router.push', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(moreCoordinatorProvider).pushVerificationManage();

      verify(() => mockRouter.push(any())).called(1);
    });
  });
}
