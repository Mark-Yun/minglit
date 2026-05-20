// EventOngoingBannerBuilder — event_ongoing_banner 전용 fluent API.
//
// EventOngoingBanner 는 순수 StatelessWidget (Riverpod 미사용).
// build() 를 override 하여 현재 _phase 값으로 위젯을 직접 생성한다.
//
// Fix #2588: mds-render-coverage event-operation 카탈로그 등록

import 'package:app_user/src/features/tickets/widgets/event_ongoing_banner.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/data.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

EventApplication _mockApplication() {
  final base = mockEventsBaseTime;
  final event = Event(
    id: 'render-event-1',
    partyId: 'render-party-1',
    title: '강남 밍릿파티',
    startTime: base.add(const Duration(hours: 2)),
    endTime: base.add(const Duration(hours: 4)),
    createdAt: base,
    updatedAt: base,
    currentParticipants: 12,
  );
  return EventApplication(
    id: 'app-1',
    eventId: event.id,
    ticketId: 'ticket-1',
    userId: 'user-1',
    status: 'approved',
    createdAt: base,
    updatedAt: base,
    event: event,
  );
}

// ---------------------------------------------------------------------------
// Builder
// ---------------------------------------------------------------------------

// _Stub 은 base class 의 W 타입 제약 충족용. build() override 로 실제론 미사용.
class _Stub extends StatelessWidget {
  const _Stub();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class EventOngoingBannerBuilder extends MdsScreenBuilder<_Stub> {
  EventOngoingBannerBuilder() : super(page: const _Stub(), base: []);

  EventLifecyclePhase _phase = EventLifecyclePhase.waiting;
  Brightness _brightness = Brightness.light;

  /// 입장 대기 상태 (MDS state_1).
  void waiting() => _phase = EventLifecyclePhase.waiting;

  /// 입장 가능 상태 (MDS state_2).
  void checkInReady() => _phase = EventLifecyclePhase.checkInReady;

  /// 체크인 완료 상태 (MDS state_3).
  void checkedIn() => _phase = EventLifecyclePhase.checkedIn;

  /// 매칭 준비 상태 (MDS state_4).
  void matchingReady() => _phase = EventLifecyclePhase.matchingReady;

  /// 매칭 진행 중 상태 (MDS state_5).
  void matching() => _phase = EventLifecyclePhase.matching;

  /// 결과 확인 필요 상태 (MDS state_6).
  void resultsUnviewed() => _phase = EventLifecyclePhase.resultsUnviewed;

  /// 결과 확인 완료 상태 (MDS state_7).
  void resultsViewed() => _phase = EventLifecyclePhase.resultsViewed;

  /// 노쇼 상태 (MDS state_8).
  void noShow() => _phase = EventLifecyclePhase.noShow;

  /// 다크 모드 토글.
  void dark() => _brightness = Brightness.dark;

  @override
  Widget build() {
    final application = _mockApplication();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _brightness == Brightness.dark
          ? MinglitTheme.materialThemeDark
          : MinglitTheme.materialTheme,
      home: Scaffold(
        body: Center(
          child: EventOngoingBanner(
            application: application,
            phase: _phase,
            onMarkResultsViewed: () {},
            onOpenDetail: () {},
            onOpenQr: () {},
            onOpenMatching: () {},
          ),
        ),
      ),
    );
  }
}
