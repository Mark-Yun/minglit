import 'package:app_partner/src/features/member/member_coordinator.dart';
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

  group('MemberCoordinator', () {
    test('creates from provider', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final notifier = container.read(memberCoordinatorProvider.notifier);
      expect(notifier, isA<MemberCoordinator>());
    });

    test('goToMemberPermission calls router.push with IDs', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final notifier = container.read(memberCoordinatorProvider.notifier);
      notifier.goToMemberPermission('partner_1', 'user_1');

      verify(() => mockRouter.push(any())).called(1);
    });
  });
}
