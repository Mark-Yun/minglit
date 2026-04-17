import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/ticket/ui/model/ticket_event_meta.dart';
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
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  group('HomeCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(homeCoordinatorProvider);

      expect(coordinator, isA<HomeCoordinator>());
    });

    test('pushNotificationCenter calls router.push', () {
      HomeCoordinator(mockRouter).pushNotificationCenter();

      verify(
        () => mockRouter.push(any(that: contains('/notifications'))),
      ).called(1);
    });

    test('pushPurchaseHistory calls router.push', () {
      HomeCoordinator(mockRouter).pushPurchaseHistory();

      verify(
        () => mockRouter.push(any(that: contains('purchase-history'))),
      ).called(1);
    });

    test('goToPurchaseHistory calls router.go', () {
      HomeCoordinator(mockRouter).goToPurchaseHistory();

      verify(
        () => mockRouter.go(any(that: contains('purchase-history'))),
      ).called(1);
    });

    test('pushNotificationSettings calls router.push', () {
      HomeCoordinator(mockRouter).pushNotificationSettings();

      verify(
        () => mockRouter.push(any(that: contains('notification-settings'))),
      ).called(1);
    });

    // Fix #404: Tests for new coordinator methods
    test('goToHome calls router.go("/")', () {
      HomeCoordinator(mockRouter).goToHome();

      verify(() => mockRouter.go('/')).called(1);
    });

    test('pushPrivacy calls router.push', () {
      HomeCoordinator(mockRouter).pushPrivacy();

      verify(
        () => mockRouter.push(any(that: contains('privacy'))),
      ).called(1);
    });

    test('pushBlockedPartners calls router.push', () {
      HomeCoordinator(mockRouter).pushBlockedPartners();

      verify(
        () => mockRouter.push(any(that: contains('blocked-partners'))),
      ).called(1);
    });

    test('pushEventDetail calls router.push with eventId', () {
      HomeCoordinator(mockRouter).pushEventDetail('evt_123');

      verify(
        () => mockRouter.push(any(that: contains('evt_123'))),
      ).called(1);
    });

    // Fix #641: pushMyTickets navigates to /tickets/my
    test('pushMyTickets calls router.push with /tickets/my', () {
      HomeCoordinator(mockRouter).pushMyTickets();

      verify(
        () => mockRouter.push(any(that: contains('/tickets/my'))),
      ).called(1);
    });

    test('pushPartnerEvents calls router.push with partnerId', () {
      HomeCoordinator(mockRouter).pushPartnerEvents(
        partnerId: 'p_1',
        partnerName: 'Test Partner',
      );

      verify(
        () => mockRouter.push(any(that: contains('p_1'))),
      ).called(1);
    });

    // Fix #1526: pushTicketQR는 eventMeta를 GoRouter.push의 extra로 전달해야 한다.
    // app_routes.g.dart의 _fromState가 state.extra를 드롭하면 이 테스트가 실패한다.
    group('pushTicketQR', () {
      setUp(() {
        when(
          () => mockRouter.push(any(), extra: any(named: 'extra')),
        ).thenAnswer((_) async => null);
      });

      test('eventMeta를 GoRouter extra로 전달한다', () {
        final meta = TicketEventMeta(
          eventTitle: '테스트 이벤트',
          eventDateTime: DateTime(2026, 5, 1, 18),
          eventVenue: '강남 라운지',
          ticketName: '일반 입장권',
        );

        HomeCoordinator(mockRouter).pushTicketQR('ticket-123', eventMeta: meta);

        final captured = verify(
          () => mockRouter.push(
            any(that: contains('ticket-123')),
            extra: captureAny(named: 'extra'),
          ),
        ).captured;

        expect(captured.single, same(meta));
      });

      test('eventMeta 없이 호출하면 extra=null로 전달한다', () {
        HomeCoordinator(mockRouter).pushTicketQR('ticket-456');

        final captured = verify(
          () => mockRouter.push(
            any(that: contains('ticket-456')),
            extra: captureAny(named: 'extra'),
          ),
        ).captured;

        expect(captured.single, isNull);
      });
    });
  });
}
