// Fix #2314: 위저드 뒤로가기 내비게이션 가드 회귀 방지 테스트
//
// 위저드 진행 중 CloseButton/Android 백키 입력 시:
//   - 확인 다이얼로그가 표시되어야 한다
//   - '계속하기' 선택 시 위저드에 머물러야 한다
//   - '나가기' 선택 시 위저드가 닫혀야 한다
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

  // Wrap with a navigator so we can verify pop behaviour.
  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        eventDetailControllerProvider(
          testEvent.id,
        ).overrideWith(() => _FakeEventDetailController(testEvent)),
        eventApplicationControllerProvider(
          testEvent,
        ).overrideWith(
          () => _FakeEventApplicationController(
            const EventApplicationState(
              step: EventApplicationStep.identity,
              status: EventApplicationStatus.initial,
              identityCompleted: false,
              partnerVerifications: [],
              consentGranted: false,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      EventApplicationWizardPage(eventId: testEvent.id),
                ),
              ),
              child: const Text('open wizard'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openWizard(WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('open wizard'));
    await tester.pumpAndSettle();
    expect(find.text('참여 신청'), findsOneWidget);
  }

  group('EventApplicationWizardPage — 뒤로가기 가드', () {
    testWidgets('Android 시스템 백키 입력 시 확인 다이얼로그가 표시된다', (tester) async {
      // Fix #2314: PopScope(canPop: false)가 시스템 백을 가로채고 다이얼로그를 보여야 함
      await openWizard(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('신청을 중단할까요?'), findsOneWidget);
    });

    testWidgets('CloseButton 탭 시 확인 다이얼로그가 표시된다', (tester) async {
      // Fix #2314: CloseButton이 이전처럼 즉시 pop하지 않고 다이얼로그를 보여야 함
      await openWizard(tester);

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      expect(find.text('신청을 중단할까요?'), findsOneWidget);
    });

    testWidgets('다이얼로그에서 "계속하기" 선택 시 위저드가 유지된다', (tester) async {
      await openWizard(tester);

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle();

      // 위저드 화면이 아직 보여야 한다
      expect(find.text('참여 신청'), findsOneWidget);
      expect(find.text('신청을 중단할까요?'), findsNothing);
    });

    testWidgets('다이얼로그에서 "나가기" 선택 시 위저드가 닫힌다', (tester) async {
      await openWizard(tester);

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();

      // 위저드가 닫히고 이전 화면으로 돌아온다
      expect(find.text('참여 신청'), findsNothing);
      expect(find.text('open wizard'), findsOneWidget);
    });
  });
}

class _FakeEventApplicationController extends EventApplicationController {
  _FakeEventApplicationController(this._initialState);

  final EventApplicationState _initialState;

  @override
  EventApplicationState build(Event event) => _initialState;

  @override
  Future<void> selectTicket(Ticket ticket) async {
    state = state.copyWith(selectedTicket: ticket);
  }
}

class _FakeEventDetailController extends EventDetailController {
  _FakeEventDetailController(this._event);

  final Event _event;

  @override
  Future<Event> build(String id) async => _event;
}
