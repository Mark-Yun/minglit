// Fix #1601: 파트너 프로필 행 탭 시 파트너 상세 화면 미진입 회귀 방지
//
// Root cause: GestureDetector에 behavior: HitTestBehavior.opaque 누락.
// Row 내 여백(SizedBox 등 투명 영역) 탭 시 히트 테스트가 실패해 onTap이 호출되지 않았음.
// 핵심 회귀 테스트: CircleAvatar와 Text 사이 투명 SizedBox 영역을 좌표로 탭 → coordinator 호출 확인.
//
// 테스트 전략: GoRouter.push() 타이밍 불확실성을 피하기 위해 EventCoordinator를 mock으로
// 교체해 pushPartnerDetail() 호출 여부를 직접 검증한다.
// Navigator 스택 변화 대신 coordinator 호출을 어설션하는 방식이 더 결정론적이다.
//
// 뷰포트 설정: EventDetailPage의 SliverAppBar는 expandedHeight = screenWidth * 9/16.
// 기본 테스트 너비 800px이면 expandedHeight=450 + 탭바(47) + 패딩(16) = 513px로,
// BottomTicketBar(~76px)를 빼면 뷰포트가 524px밖에 안 되어 파트너 행 중심(y≈525)이
// 뷰포트 밖으로 밀려난다. 너비 400px로 설정하면 expandedHeight=225로 충분한 여백 확보.
import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/event_detail_now_provider.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../integration/utils/test_app.dart';

class _MockEventCoordinator extends Mock implements EventCoordinator {}

class _DataEventDetailController extends EventDetailController {
  _DataEventDetailController(this._event);
  final Event _event;

  @override
  FutureOr<Event> build(String eventId) async => _event;
}

class _GuestAdmissionController extends EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) async {
    return AdmissionState(status: EventAdmissionStatus.guest);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  const partnerId = 'test-partner-id';
  const partnerName = '테스트 파트너';
  final now = DateTime(2026, 4, 19, 10);

  final testEvent = Event(
    id: 'test-event-id',
    partyId: 'test-party-id',
    startTime: now.add(const Duration(days: 7)),
    endTime: now.add(const Duration(days: 7, hours: 3)),
    createdAt: now,
    updatedAt: now,
    party: Party(
      id: 'test-party-id',
      partnerId: partnerId,
      title: '테스트 파티',
      createdAt: now,
      updatedAt: now,
      partner: const Partner(id: partnerId, name: partnerName),
    ),
    tickets: [
      Ticket(
        id: 'test-ticket-1',
        name: 'General',
        price: 10000,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );

  group('EventDetail 파트너 행 탭 네비게이션', () {
    late _MockEventCoordinator mockCoordinator;

    setUp(() {
      mockCoordinator = _MockEventCoordinator();
      when(() => mockCoordinator.pushPartnerDetail(any())).thenReturn(null);
    });

    Future<void> pumpEventDetailPage(WidgetTester tester) async {
      setKoreanLocale(tester);

      // Fix #1677: 너비를 400px로 제한해 SliverAppBar expandedHeight(=400*9/16=225)가
      // 파트너 행을 뷰포트 안에 유지하도록 한다. 기본 800px이면 파트너 행 중심이 뷰포트 밖.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/events/test-event-id',
          additionalOverrides: [
            eventDetailControllerProvider(
              'test-event-id',
            ).overrideWith(() => _DataEventDetailController(testEvent)),
            eventAdmissionControllerProvider(
              testEvent,
            ).overrideWith(_GuestAdmissionController.new),
            eventDetailNowProvider.overrideWith(
              (_) =>
                  () => now,
            ),
            entryGroupParticipantCountsProvider(
              'test-event-id',
            ).overrideWith((_) async => <String, int>{}),
            // Fix #1677: EventCoordinator 모킹으로 GoRouter.push() 타이밍 의존성 제거
            eventCoordinatorProvider.overrideWithValue(mockCoordinator),
          ],
        ),
      );

      // pump without pumpAndSettle — EventDetailPage has internal timers
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
    }

    // Fix #1601 핵심 회귀 테스트: HitTestBehavior.opaque 없으면 이 테스트가 red가 된다.
    // Text 위젯은 자체 RenderObject로 히트 테스트에 응답하므로 텍스트 탭으로는 검증 불가.
    // CircleAvatar와 Text 사이 투명 SizedBox 영역을 좌표로 탭해야 실제 버그를 재현한다.
    testWidgets('파트너 행의 투명 여백 탭 시 pushPartnerDetail이 호출된다', (tester) async {
      await pumpEventDetailPage(tester);

      expect(find.text(partnerName), findsOneWidget);

      final gestureFinder = find
          .ancestor(
            of: find.text(partnerName),
            matching: find.byType(GestureDetector),
          )
          .first;
      final avatarFinder = find
          .descendant(
            of: gestureFinder,
            matching: find.byType(CircleAvatar),
          )
          .first;

      final gestureRect = tester.getRect(gestureFinder);
      final avatarRect = tester.getRect(avatarFinder);
      final textRect = tester.getRect(find.text(partnerName));

      // CircleAvatar 오른쪽 끝과 Text 왼쪽 끝 사이의 투명 SizedBox 중간 지점
      final gapCenter = Offset(
        (avatarRect.right + textRect.left) / 2,
        gestureRect.center.dy,
      );

      await tester.tapAt(gapCenter);
      await tester.pump();

      verify(() => mockCoordinator.pushPartnerDetail(partnerId)).called(1);
    });

    testWidgets('파트너 이름 탭 시 pushPartnerDetail이 호출된다', (tester) async {
      await pumpEventDetailPage(tester);

      expect(find.text(partnerName), findsOneWidget);

      await tester.tap(find.text(partnerName));
      await tester.pump();

      verify(() => mockCoordinator.pushPartnerDetail(partnerId)).called(1);
    });
  });
}
