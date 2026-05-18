// CUJ tests — event / event-edit-cancel (app_user 관점)
//
// 대응 spec: docs/features/event/event-edit-cancel/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위:
//   - CUJ 4-2: 유저앱에서 취소된 이벤트 표시 (P1)
//
// 참고: CUJ 1-1 ~ 4-1 은 파트너 앱(app_partner) 에서 구현되며
//       apps/app_partner/integration_test/cuj/event/event_edit_cancel_test.dart 에 위치.
//       app_user 는 유저 관점 CUJ (취소된 이벤트 표시, 신청 차단) 만 커버.
//
// 설계 결정:
//   - EventDetailPage(eventId) 렌더 — eventDetailControllerProvider 가
//     eventRepositoryProvider.getEventById 를 통해 Event 를 fetch.
//   - eventAdmissionControllerProvider(event) 는 currentUserProvider 를 읽어
//     취소/종료 이벤트에서 EventAdmissionStatus.eventEnded 를 반환.
//   - 비로그인(currentUserProvider=null) + status='cancelled' 조합으로
//     "종료된 이벤트" 버튼 (disabled) 을 최소 의존성으로 검증.
//   - entryGroupParticipantCountsProvider 는 빈 리스트로 stubbing.

import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockEventRepository extends Mock implements EventRepository {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _baseTime = DateTime(2026, 5, 20, 19, 0);

Event _makeEvent({
  String id = 'event-1',
  String status = 'scheduled',
}) {
  return Event(
    id: id,
    partyId: 'party-1',
    title: '테스트 이벤트',
    startTime: _baseTime.add(const Duration(days: 3)),
    endTime: _baseTime.add(const Duration(days: 3, hours: 2)),
    createdAt: _baseTime,
    updatedAt: _baseTime,
    status: status,
    tickets: const [],
    entryGroups: const [],
  );
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockEventRepository mockRepo;

  setUp(() {
    mockRepo = _MockEventRepository();
    when(
      () => mockRepo.getEntryGroupParticipantCounts(any()),
    ).thenAnswer((_) async => []);
  });

  // 비로그인 + cancelled event: eventAdmissionController 가 eventEnded 반환.
  List<dynamic> base() => [
    eventRepositoryProvider.overrideWithValue(mockRepo),
    currentUserProvider.overrideWith((_) => null),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
  ];

  // ===========================================================================
  // CUJ 4-2: 유저앱에서 취소된 이벤트 표시
  // ===========================================================================
  cujGroup('4-2', '유저앱에서 취소된 이벤트 표시', () {
    cujCase(
      'happy: 취소된 이벤트 → "종료된 이벤트" 버튼 비활성',
      app: const EventDetailPage(eventId: 'event-1'),
      overrides: () {
        final event = _makeEvent(status: 'cancelled');
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 취소된 이벤트는 AdmissionStatus.eventEnded → "종료된 이벤트" (disabled)
        // Fix #1208: ended event button config
        final endedBtn = t.widget<MinglitButton>(
          find.widgetWithText(MinglitButton, '종료된 이벤트'),
        );
        expect(endedBtn.onPressed, isNull);
      },
    );

    cujCase(
      'edge: 취소된 이벤트 딥링크 진입 → 신규 신청 버튼 미노출',
      app: const EventDetailPage(eventId: 'event-1'),
      overrides: () {
        final event = _makeEvent(status: 'cancelled');
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 신청하기 / 참가 신청하기 버튼 미노출 (FR-12: 신규 신청 차단)
        expect(find.widgetWithText(MinglitButton, '참가 신청하기'), findsNothing);
        expect(find.widgetWithText(MinglitButton, '신청하기'), findsNothing);

        // 이벤트 제목은 정상 표시
        expect(find.text('테스트 이벤트'), findsWidgets);
      },
    );

    cujCase(
      'edge: 이벤트 fetch 실패 → 에러 상태 표시',
      app: const EventDetailPage(eventId: 'event-error'),
      overrides: () {
        when(
          () => mockRepo.getEventById('event-error'),
        ).thenThrow(Exception('network error'));
        when(
          () => mockRepo.getEntryGroupParticipantCounts('event-error'),
        ).thenAnswer((_) async => []);
        return [
          eventRepositoryProvider.overrideWithValue(mockRepo),
          currentUserProvider.overrideWith((_) => null),
          authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        ];
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 에러 상태 — MinglitErrorState 표시
        expect(find.text('이벤트를 불러올 수 없습니다'), findsOneWidget);
      },
    );
  });
}
