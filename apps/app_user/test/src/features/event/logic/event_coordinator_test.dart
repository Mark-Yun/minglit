import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;
  late EventCoordinator coordinator;

  setUp(() {
    mockRouter = MockGoRouter();
    coordinator = EventCoordinator(mockRouter);

    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  group('EventCoordinator', () {
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
      ).called(1);
    });

    // Fix #634: pushLogin 테스트 추가
    test('pushLogin pushes login route', () {
      coordinator.pushLogin();

      verify(
        () => mockRouter.push('/login'),
      ).called(1);
    });

    // Fix #634: from 쿼리 파라미터 값까지 검증
    test('pushLogin with from param includes query param', () {
      coordinator.pushLogin(from: '/events/123');

      verify(
        () => mockRouter.push(
          any(
            that: allOf(contains('/login'), contains('from=%2Fevents%2F123')),
          ),
        ),
      ).called(1);
    });
  });
}
