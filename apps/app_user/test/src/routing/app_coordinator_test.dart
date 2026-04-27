import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/ticket/ui/model/ticket_event_meta.dart';
import 'package:app_user/src/routing/app_coordinator.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/test_utils.dart';

class MockGoRouter extends Mock implements GoRouter {}

class MockAccountDeletionCoordinator extends Mock
    implements AccountDeletionCoordinator {}

void main() {
  late MockGoRouter mockRouter;
  late MockAccountDeletionCoordinator mockDeletion;

  setUp(() {
    mockRouter = MockGoRouter();
    mockDeletion = MockAccountDeletionCoordinator();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    when(
      () => mockRouter.push(any(), extra: any(named: 'extra')),
    ).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
    when(() => mockDeletion.start()).thenReturn(null);
  });

  group('AppCoordinator', () {
    test('creates from provider', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
          accountDeletionCoordinatorProvider.overrideWithValue(mockDeletion),
        ],
      );

      final coordinator = container.read(appCoordinatorProvider);

      expect(coordinator, isA<AppCoordinator>());
    });

    test('goToHome calls router.go("/")', () {
      AppCoordinator(mockRouter, mockDeletion).goToHome();

      verify(() => mockRouter.go('/')).called(1);
    });

    test('goToLogin calls router.go with login route', () {
      AppCoordinator(mockRouter, mockDeletion).goToLogin();

      verify(() => mockRouter.go(any(that: contains('/login')))).called(1);
    });

    test('goToLogin passes from parameter', () {
      AppCoordinator(mockRouter, mockDeletion).goToLogin(from: '/my');

      verify(
        () => mockRouter.go(any(that: contains('/login'))),
      ).called(1);
    });

    test('pushEventDetail calls router.push with eventId', () {
      AppCoordinator(mockRouter, mockDeletion).pushEventDetail('evt_123');

      verify(
        () => mockRouter.push(any(that: contains('evt_123'))),
      ).called(1);
    });

    test('startAccountDeletion delegates to AccountDeletionCoordinator', () {
      AppCoordinator(mockRouter, mockDeletion).startAccountDeletion();

      verify(() => mockDeletion.start()).called(1);
    });

    // Fix #1526: pushTicketQR는 eventMeta를 GoRouter.push의 extra로 전달해야 한다.
    // app_routes.g.dart의 _fromState가 state.extra를 드롭하면 이 테스트가 실패한다.
    // Moved from home_coordinator_test.dart in #1956 (pushTicketQR is now on
    // AppCoordinator to break the home→ticket cross-feature import).
    group('pushTicketQR', () {
      test('eventMeta를 GoRouter extra로 전달한다', () {
        final meta = TicketEventMeta(
          eventTitle: '테스트 이벤트',
          eventDateTime: DateTime(2026, 5, 1, 18),
          eventVenue: '강남 라운지',
          ticketName: '일반 입장권',
        );

        AppCoordinator(mockRouter, mockDeletion).pushTicketQR(
          'ticket-123',
          eventMeta: meta,
        );

        final captured = verify(
          () => mockRouter.push(
            any(that: contains('ticket-123')),
            extra: captureAny(named: 'extra'),
          ),
        ).captured;

        expect(captured.single, same(meta));
      });

      test('eventMeta 없이 호출하면 extra=null로 전달한다', () {
        AppCoordinator(mockRouter, mockDeletion).pushTicketQR('ticket-456');

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
