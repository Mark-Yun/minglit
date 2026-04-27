import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/routing/app_coordinator.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/test_utils.dart';

class MockGoRouter extends Mock implements GoRouter {}

class MockAppCoordinator extends Mock implements AppCoordinator {}

void main() {
  late MockGoRouter mockRouter;
  late MockAppCoordinator mockApp;

  setUp(() {
    mockRouter = MockGoRouter();
    mockApp = MockAppCoordinator();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
    when(() => mockApp.goToHome()).thenReturn(null);
    when(() => mockApp.goToLogin()).thenReturn(null);
    when(() => mockApp.goToLogin(from: any(named: 'from'))).thenReturn(null);
    when(() => mockApp.pushEventDetail(any())).thenReturn(null);
  });

  group('HomeCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
          appCoordinatorProvider.overrideWithValue(mockApp),
        ],
      );

      final coordinator = container.read(homeCoordinatorProvider);

      expect(coordinator, isA<HomeCoordinator>());
    });

    test('pushNotificationCenter calls router.push', () {
      HomeCoordinator(mockRouter, mockApp).pushNotificationCenter();

      verify(
        () => mockRouter.push(any(that: contains('/notifications'))),
      ).called(1);
    });

    test('pushPurchaseHistory calls router.push', () {
      HomeCoordinator(mockRouter, mockApp).pushPurchaseHistory();

      verify(
        () => mockRouter.push(any(that: contains('purchase-history'))),
      ).called(1);
    });

    test('goToPurchaseHistory calls router.go', () {
      HomeCoordinator(mockRouter, mockApp).goToPurchaseHistory();

      verify(
        () => mockRouter.go(any(that: contains('purchase-history'))),
      ).called(1);
    });

    test('pushNotificationSettings calls router.push', () {
      HomeCoordinator(mockRouter, mockApp).pushNotificationSettings();

      verify(
        () => mockRouter.push(any(that: contains('notification-settings'))),
      ).called(1);
    });

    // Fix #404: goToHome delegates to AppCoordinator — refactored in #1956
    test('goToHome delegates to AppCoordinator', () {
      HomeCoordinator(mockRouter, mockApp).goToHome();

      verify(() => mockApp.goToHome()).called(1);
      verifyNever(() => mockRouter.go(any()));
    });

    test('pushPrivacy calls router.push', () {
      HomeCoordinator(mockRouter, mockApp).pushPrivacy();

      verify(
        () => mockRouter.push(any(that: contains('privacy'))),
      ).called(1);
    });

    test('pushBlockedPartners calls router.push', () {
      HomeCoordinator(mockRouter, mockApp).pushBlockedPartners();

      verify(
        () => mockRouter.push(any(that: contains('blocked-partners'))),
      ).called(1);
    });

    // pushEventDetail delegates to AppCoordinator — refactored in #1956
    test('pushEventDetail delegates to AppCoordinator', () {
      HomeCoordinator(mockRouter, mockApp).pushEventDetail('evt_123');

      verify(() => mockApp.pushEventDetail('evt_123')).called(1);
      verifyNever(() => mockRouter.push(any()));
    });

    // Fix #641: pushMyTickets navigates to /tickets/my
    test('pushMyTickets calls router.push with /tickets/my', () {
      HomeCoordinator(mockRouter, mockApp).pushMyTickets();

      verify(
        () => mockRouter.push(any(that: contains('/tickets/my'))),
      ).called(1);
    });

    test('pushPartnerEvents calls router.push with partnerId', () {
      HomeCoordinator(mockRouter, mockApp).pushPartnerEvents(
        partnerId: 'p_1',
        partnerName: 'Test Partner',
      );

      verify(
        () => mockRouter.push(any(that: contains('p_1'))),
      ).called(1);
    });

    // Fix #1630: AppBar 검색·프로필 아이콘이 GoRouter 주입 coordinator를 통해 네비게이션하는지 검증.
    // context.push() / GoRouteData.push(context) 로 되돌리면 이 테스트가 실패한다.
    test('pushSearch calls router.push with /search', () {
      HomeCoordinator(mockRouter, mockApp).pushSearch();

      verify(
        () => mockRouter.push(any(that: contains('/search'))),
      ).called(1);
    });

    test('pushMyPage calls router.push with /my', () {
      HomeCoordinator(mockRouter, mockApp).pushMyPage();

      verify(
        () => mockRouter.push(any(that: contains('/my'))),
      ).called(1);
    });
  });
}
