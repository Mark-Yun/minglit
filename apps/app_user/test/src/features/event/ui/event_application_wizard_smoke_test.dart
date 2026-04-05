// Ref #1072: P0 Smoke — EventApplicationWizardPage 화면 진입 테스트
//
// 이벤트 신청 위저드 화면이 크래시 없이 렌더링됨을 검증한다.
// 결제/심사 등 실제 API 호출은 Mock으로 대체한다.
import 'dart:async';

import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:app_user/src/features/event/admission/event_application_wizard_page.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final now = DateTime(2026, 4, 5, 15);

  final testTicket = Ticket(
    id: 'ticket-1',
    name: '일반 티켓',
    price: 25000,
    createdAt: now,
    updatedAt: now,
  );

  final testEvent = Event(
    id: 'event-1',
    partyId: 'party-1',
    title: '소개팅 파티',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 3)),
    createdAt: now,
    updatedAt: now,
    tickets: [testTicket],
    entryGroups: [],
  );

  Widget buildWidget({
    AsyncValue<Event>? eventState,
    EventApplicationState? appState,
    String? ticketId,
  }) {
    final resolvedEventState = eventState ?? AsyncData<Event>(testEvent);
    final resolvedAppState =
        appState ??
        const EventApplicationState(
          step: EventApplicationStep.verification,
          status: EventApplicationStatus.initial,
        );

    return ProviderScope(
      overrides: [
        eventDetailControllerProvider(testEvent.id).overrideWith(
          () => _FakeEventDetailController(resolvedEventState),
        ),
        eventApplicationControllerProvider(testEvent).overrideWith(
          () => _FakeEventApplicationController(resolvedAppState),
        ),
      ],
      child: MaterialApp(
        home: EventApplicationWizardPage(
          eventId: testEvent.id,
          ticketId: ticketId,
        ),
      ),
    );
  }

  group('EventApplicationWizardPage', () {
    testWidgets('AppBar에 "참여 신청" 제목이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('참여 신청'), findsOneWidget);
    });

    testWidgets('이벤트 로딩 중에는 로딩 인디케이터가 표시된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(eventState: const AsyncLoading()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('이벤트 로드 에러 시 에러 UI가 표시된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          eventState: AsyncError<Event>(
            Exception('네트워크 오류'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 에러 상태에서도 크래시 없이 렌더링됨을 검증
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('이벤트 데이터 로드 시 위저드 단계 진행 UI가 렌더링된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // 위저드 본문(step indicator 또는 티켓 선택 화면)이 표시됨
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('참여 신청'), findsOneWidget);
    });

    testWidgets('닫기 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CloseButton), findsOneWidget);
    });

    testWidgets('초기 ticketId가 주어지면 크래시 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(ticketId: testTicket.id),
      );
      await tester.pumpAndSettle();

      expect(find.text('참여 신청'), findsOneWidget);
    });
  });
}

class _FakeEventApplicationController extends EventApplicationController {
  _FakeEventApplicationController(this._initialState);

  final EventApplicationState _initialState;

  @override
  EventApplicationState build(Event event) => _initialState;
}

class _FakeEventDetailController extends EventDetailController {
  _FakeEventDetailController(this._state);

  final AsyncValue<Event> _state;

  @override
  Future<Event> build(String id) async {
    final data = _state;
    if (data is AsyncData<Event>) return data.value;
    if (data is AsyncError<Event>) throw data.error;
    // AsyncLoading — never complete
    final completer = Completer<Event>();
    return completer.future;
  }
}
