// MyTicketsPageBuilder — my_tickets_page 전용 fluent API.

import 'package:app_user/src/features/tickets/active_event_banners_provider.dart';
import 'package:app_user/src/features/tickets/my_tickets_page.dart';
import 'package:app_user/src/routing/app_coordinator.dart';
import 'package:minglit_demo/minglit_demo.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

EventApplication _mockApplication({
  required String id,
  required String title,
  required DateTime startTime,
}) {
  final event = Event(
    id: 'event-$id',
    partyId: 'party-$id',
    title: title,
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 2)),
    createdAt: DemoWorld.now,
    updatedAt: DemoWorld.now,
    currentParticipants: 24,
  );

  return EventApplication(
    id: id,
    eventId: event.id,
    ticketId: 'ticket-$id',
    userId: 'user-render-1',
    status: 'approved',
    createdAt: DemoWorld.now,
    updatedAt: DemoWorld.now,
    event: event,
  );
}

class MyTicketsPageBuilder extends MdsScreenBuilder<MyTicketsPage> {
  MyTicketsPageBuilder()
    : super(
        page: const MyTicketsPage(),
        base: [
          appCoordinatorProvider.overrideWithValue(MockAppCoordinator()),
        ],
      );

  /// 기본 상태: 활성 이벤트 banner 2개.
  MyTicketsPageBuilder withActiveBanners() {
    final now = DemoWorld.now;
    final items = <ActiveEventBannerItem>[
      (
        application: _mockApplication(
          id: 'app-1',
          title: '강남 밍릿파티',
          startTime: now.add(const Duration(hours: 1)),
        ),
        phase: EventLifecyclePhase.checkInReady,
      ),
      (
        application: _mockApplication(
          id: 'app-2',
          title: '홍대 밍글나잇',
          startTime: now.add(const Duration(hours: 3)),
        ),
        phase: EventLifecyclePhase.waiting,
      ),
    ];
    addOverride(
      activeEventBannersProvider.overrideWith((_) async => items),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 활성 이벤트 없음 (empty state).
  MyTicketsPageBuilder empty() {
    addOverride(
      activeEventBannersProvider.overrideWith((_) async => const []),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 다크 모드.
  MyTicketsPageBuilder dark() {
    useDarkTheme();
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }
}
