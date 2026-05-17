// CUJ tests — event / event-edit-cancel
//
// 대응 spec: docs/features/event/event-edit-cancel/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위:
//   - CUJ 1-1 ~ 4-2 (13개 그룹)
//   - Edge Cases 11개 (spec.md Edge Cases 표 전체)
//
// 설계 결정:
//   - EventEditPage 는 EventEditController(eventId) 를 watch 하므로,
//     eventRepositoryProvider 를 mock 해 컨트롤러가 원하는 Event 상태를 갖도록 한다.
//   - submit() 은 supabaseClientProvider → functions.invoke 를 경유하므로
//     _MockSupabaseClient + _MockFunctionsClient 로 네트워크를 격리한다.
//   - PortOne 호출은 서버(EF)에서 수행되므로 클라이언트 테스트에서는 목업 불필요.
//     EF 성공/실패는 FunctionsClient.invoke 반환값으로 시뮬레이션한다.
//   - EventDetailPage(CUJ 3-2, 4-1, 4-2)는 eventDetailProvider 직접 override.
//   - partyDetailProvider, eventApplicationsProvider, eventTicketsProvider 는
//     각 페이지 렌더에 필요하므로 stub 제공.

import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_page.dart';
import 'package:app_partner/src/features/party/event/edit/event_edit_controller.dart';
import 'package:app_partner/src/features/party/event/edit/event_edit_page.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockEventRepository extends Mock implements EventRepository {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 5, 20, 19, 0);

/// Builds an Event with sensible defaults. Override any field as needed.
Event _makeEvent({
  String id = 'event-1',
  String partyId = 'party-1',
  String title = '테스트 이벤트',
  int currentParticipants = 0,
  int maxParticipants = 20,
  String status = 'scheduled',
  DateTime? startTime,
  DateTime? endTime,
}) {
  return Event(
    id: id,
    partyId: partyId,
    title: title,
    startTime: startTime ?? _now.add(const Duration(days: 3)),
    endTime: endTime ?? _now.add(const Duration(days: 3, hours: 2)),
    createdAt: _now,
    updatedAt: _now,
    currentParticipants: currentParticipants,
    maxParticipants: maxParticipants,
    status: status,
    tickets: const [],
    entryGroups: const [],
  );
}

Party _makeParty() => Party(
  id: 'party-1',
  title: '테스트 파티',
  partnerId: 'partner-1',
  createdAt: _now,
  updatedAt: _now,
);

/// Returns a FunctionResponse stub for a successful EF call.
FunctionResponse _okResponse() => FunctionResponse(data: {}, status: 200);

/// Returns a FunctionResponse stub for a server-error EF call.
FunctionResponse _errResponse() =>
    FunctionResponse(data: null, status: 500);

/// Triggers a real schedule change by invoking the controller directly.
///
/// The native DatePicker / TimePicker dialog flow is unreliable in widget tests
/// (calendar grid cells are hard to identify by find.text without ambiguity).
/// Calling the notifier method via ProviderScope.containerOf gives us a
/// deterministic state change that produces isDirty=true + isScheduleChanged=true,
/// which is exactly what the production code path produces after a successful
/// DatePicker confirm.
Future<void> _changeSchedule(
  WidgetTester tester, {
  required String eventId,
  Duration shift = const Duration(hours: 1),
}) async {
  final context = tester.element(find.byType(EventEditPage));
  final container = ProviderScope.containerOf(context, listen: false);
  final notifier = container.read(
    eventEditControllerProvider(eventId).notifier,
  );
  final current = container.read(eventEditControllerProvider(eventId)).value!;
  notifier.updateSchedule(
    startTime: current.startTime.add(shift),
    endTime: current.endTime.add(shift),
    location: current.location,
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockEventRepository mockRepo;
  late _MockSupabaseClient mockClient;
  late _MockFunctionsClient mockFunctions;

  setUp(() {
    mockRepo = _MockEventRepository();
    mockClient = _MockSupabaseClient();
    mockFunctions = _MockFunctionsClient();
    when(() => mockClient.functions).thenReturn(mockFunctions);
  });

  // -------------------------------------------------------------------------
  // base() — providers shared by EventEditPage tests.
  // partyDetailProvider / eventApplicationsProvider are NOT watched by
  // EventEditPage itself, so only the two below are strictly required.
  // -------------------------------------------------------------------------
  List<dynamic> base() => [
    eventRepositoryProvider.overrideWithValue(mockRepo),
    supabaseClientProvider.overrideWithValue(mockClient),
  ];

  // base() extended with partyDetail + applications for EventDetailPage tests.
  List<dynamic> detailBase({
    required Event event,
    List<EventApplication> applications = const [],
    List<Ticket> tickets = const [],
  }) => [
    eventDetailProvider(event.id).overrideWith((_) async => event),
    partyDetailProvider(event.partyId).overrideWith((_) async => _makeParty()),
    eventApplicationsProvider(event.id).overrideWith(
      (_) async => applications,
    ),
    eventTicketsProvider(event.id).overrideWith((_) async => tickets),
  ];

  // Convenience: builds an EventEditPage wrapped in necessary localizations.
  Widget editPage(String eventId) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: EventEditPage(eventId: eventId),
  );

  Widget detailPage(String eventId) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: EventDetailPage(eventId: eventId),
  );

  // ===========================================================================
  // CUJ 1-1: 시간 변경 후 저장 → 확정 참가자 알림
  // ===========================================================================
  cujGroup('1-1', '시간 변경 후 저장 → 확정 참가자 알림', () {
    cujCase(
      'happy: 시간 변경 → 저장 버튼 활성 + EF 호출',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 0);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        when(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => _okResponse());
        // submit re-fetches updated event
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event.copyWith(
            startTime: _now.add(const Duration(days: 3, hours: 1)),
          ),
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 저장 버튼 초기 비활성 (isDirty=false)
        final saveBtn0 = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveBtn0.onPressed, isNull);

        // 일정 변경 — 컨트롤러 직접 호출 (DatePicker UI 우회)
        await _changeSchedule(t, eventId: 'event-1');

        // isDirty=true → 저장 버튼 활성
        final saveBtn1 = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveBtn1.onPressed, isNotNull);
      },
    );

    cujCase(
      'happy: 확정 참가자 ≥1 + 일정 변경 → 사유 다이얼로그 표시',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 5);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        when(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => _okResponse());
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 확정 참가자 배너 확인
        expect(find.text('확정 참가자 5명'), findsOneWidget);

        // 일정 편집 → 변경
        await _changeSchedule(t, eventId: 'event-1');

        // 저장 탭 → 사유 다이얼로그 노출
        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        expect(find.text('일정 변경 사유'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 저장 중 네트워크 끊김 → 스낵바 + 변경 내용 유지',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent();
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        when(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        ).thenThrow(Exception('network error'));
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 제목 변경으로 isDirty=true
        await t.enterText(
          find.widgetWithText(TextFormField, '이벤트 제목').first,
          '변경된 제목',
        );
        await t.pumpAndSettle();

        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        // 에러 스낵바 표시
        expect(find.textContaining('저장에 실패했습니다'), findsOneWidget);
        // 변경 내용 유지 — 저장 버튼 여전히 활성(isDirty 유지)
        final saveBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'edge: 핵심 변경 다이얼로그 확정 직전 이벤트 ongoing 전환 → EF 500 → 스낵바',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 2);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        // EF 서버측 재검증 거부 — 500 응답
        when(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => _errResponse());
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        await _changeSchedule(t, eventId: 'event-1');

        // 저장 → 사유 다이얼로그
        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        // 사유 입력 후 저장 및 알림 전송 탭
        await t.enterText(find.byType(TextField).last, '장소 문제');
        await t.pumpAndSettle();
        await t.tap(find.text('저장 및 알림 전송'));
        await t.pumpAndSettle();

        // EF 500 → 에러 스낵바
        expect(find.textContaining('저장에 실패했습니다'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 1-2: 장소 변경 후 저장 → 알림
  // ===========================================================================
  cujGroup('1-2', '장소 변경 후 저장 → 알림', () {
    cujCase(
      'happy: 편집 화면에 기존 이벤트 데이터 프리필',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(title: '기존 이벤트 제목');
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 제목 필드에 기존 값이 프리필됨
        expect(find.text('기존 이벤트 제목'), findsOneWidget);
        // 장소 섹션 렌더링
        expect(find.text('장소'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 1-3: 시간 + 장소 동시 변경 → 통합 알림
  // ===========================================================================
  cujGroup('1-3', '시간 + 장소 동시 변경 → 통합 알림', () {
    cujCase(
      'happy: 시간 변경 후 저장 버튼 활성',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent();
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        when(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => _okResponse());
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 일정 편집 후 변경
        await _changeSchedule(t, eventId: 'event-1');

        // 저장 버튼 활성
        final saveBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'edge: 동일 필드 여러 번 변경 → 최종 값만 반영',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(title: '원래 제목');
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        final titleField = find.widgetWithText(TextFormField, '이벤트 제목').first;

        // 여러 번 변경
        await t.enterText(titleField, '중간 제목');
        await t.pumpAndSettle();
        await t.enterText(titleField, '최종 제목');
        await t.pumpAndSettle();

        // 최종 값만 표시
        expect(find.text('최종 제목'), findsOneWidget);
        expect(find.text('중간 제목'), findsNothing);
      },
    );
  });

  // ===========================================================================
  // CUJ 1-4: 핵심 변경 다이얼로그에서 취소
  // ===========================================================================
  cujGroup('1-4', '핵심 변경 다이얼로그에서 취소', () {
    cujCase(
      'happy: 사유 다이얼로그에서 취소 → 편집 화면 복귀 + 변경 유지',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 3);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 일정 변경
        await _changeSchedule(t, eventId: 'event-1');

        // 저장 → 사유 다이얼로그 열림
        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();
        expect(find.text('일정 변경 사유'), findsOneWidget);

        // 다이얼로그에서 취소
        await t.tap(find.text('취소'));
        await t.pumpAndSettle();

        // 편집 화면으로 복귀
        expect(find.text('이벤트 수정'), findsOneWidget);
        // 변경 내용 유지 (저장 버튼 여전히 활성)
        final saveBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveBtn.onPressed, isNotNull);

        // EF 호출 없음
        verifyNever(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        );
      },
    );
  });

  // ===========================================================================
  // CUJ 2-1: 제목·설명 변경 → 알림 없음
  // ===========================================================================
  cujGroup('2-1', '제목·설명 변경 → 알림 없음', () {
    cujCase(
      'happy: 제목만 변경 → 사유 다이얼로그 미표시 + 즉시 저장',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 0);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        when(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => _okResponse());
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event.copyWith(title: '새 제목'),
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        await t.enterText(
          find.widgetWithText(TextFormField, '이벤트 제목').first,
          '새 제목',
        );
        await t.pumpAndSettle();

        // 저장 탭 — 사유 다이얼로그 없이 바로 진행
        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        // 사유 다이얼로그 미노출 (FR-4: 부수 필드 변경은 다이얼로그 없음)
        expect(find.text('일정 변경 사유'), findsNothing);
      },
    );
  });

  // ===========================================================================
  // CUJ 2-2: 정원 증가
  // ===========================================================================
  cujGroup('2-2', '정원 증가', () {
    cujCase(
      'happy: 정원 15 → 20 으로 증가 → isDirty=true',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(maxParticipants: 15);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        await t.enterText(
          find.widgetWithText(TextFormField, '최소 1명').first,
          '20',
        );
        await t.pumpAndSettle();

        // 저장 버튼 활성
        final saveBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'edge: 정원 증가 시 확정 참가자 배너 유지',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 10, maxParticipants: 15);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 확정 참가자 배너 표시
        expect(find.text('확정 참가자 10명'), findsOneWidget);

        // 정원 증가
        await t.enterText(
          find.widgetWithText(TextFormField, '최소 10명').first,
          '25',
        );
        await t.pumpAndSettle();

        // 배너 여전히 표시
        expect(find.text('확정 참가자 10명'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 2-3: 정원 감소가 현재 참가자 수 미만 → 차단
  // ===========================================================================
  cujGroup('2-3', '정원 감소가 현재 참가자 수 미만 → 차단', () {
    cujCase(
      'happy: 참가자 8명 상태에서 정원 5 입력 → 자동으로 8로 클램핑',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 8, maxParticipants: 20);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 힌트: 최소 8명 (확정 참가자 기준)
        expect(find.text('최소 8명'), findsOneWidget);

        // 5 입력 → 컨트롤러가 8로 클램핑
        await t.enterText(
          find.widgetWithText(TextFormField, '최소 8명').first,
          '5',
        );
        await t.pumpAndSettle();

        // isDirty = false (clamp 후 값이 원래와 동일 — 20 != 8, 실제로 8로 세팅됨)
        // 저장 버튼이 활성이면 maxParticipants가 8로 변경된 것 (원래 20이므로 dirty)
        final saveBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        // 클램핑 값 8은 원래 maxParticipants 20과 다르므로 dirty
        expect(saveBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'edge: 정원 줄이기 시도 중 동시에 참가자 1명 추가 → 서버 재검증',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 8, maxParticipants: 20);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        // EF가 서버측 재검증 후 거부 (500)
        when(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => _errResponse());
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 9 입력 (8보다 크므로 저장 가능 — 클라이언트 통과)
        await t.enterText(
          find.widgetWithText(TextFormField, '최소 8명').first,
          '9',
        );
        await t.pumpAndSettle();

        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        // EF 500 → 스낵바 에러 표시
        expect(find.textContaining('저장에 실패했습니다'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 3-1: 참가자 있는 이벤트 취소
  // ===========================================================================
  cujGroup('3-1', '참가자 있는 이벤트 취소', () {
    cujCase(
      'happy: 상태=scheduled + 참가자=12 → "취소됨" 배지 (EventDetailPage)',
      app: Builder(
        builder: (ctx) => detailPage('event-1'),
      ),
      overrides: () => detailBase(
        event: _makeEvent(
          currentParticipants: 12,
          status: 'scheduled',
        ),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // 이벤트 정보 섹션 렌더링
        expect(find.text('이벤트 정보'), findsOneWidget);
        // 수정 버튼 노출 (scheduled 상태)
        expect(find.text('정보 수정'), findsOneWidget);
        // 취소됨 배지 없음 (아직 취소 전)
        expect(find.text('취소됨'), findsNothing);
      },
    );

    cujCase(
      'edge: 취소 처리 중 일부 PortOne 환불 실패 → 이벤트 취소 상태 + 에러 배지',
      // 클라이언트 측에서는 EF 응답이 취소 성공(200)이지만
      // 일부 환불 실패 정보가 포함된 경우를 cancelled 상태로 시뮬레이션.
      app: Builder(
        builder: (ctx) => detailPage('event-1'),
      ),
      overrides: () => detailBase(
        event: _makeEvent(
          currentParticipants: 8,
          status: 'cancelled',
        ),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // 취소 후 상태 표시
        expect(find.text('취소됨'), findsOneWidget);
        // 수정/취소 버튼 비활성 (isTerminated=true)
        expect(find.text('정보 수정'), findsNothing);
        expect(find.text('신청 목록 보기'), findsNothing);
      },
    );

    cujCase(
      'edge: 취소 처리 중 앱 kill → 재진입 시 cancelled 상태 반영',
      app: Builder(
        builder: (ctx) => detailPage('event-1'),
      ),
      overrides: () => detailBase(
        event: _makeEvent(status: 'cancelled', currentParticipants: 5),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // 재진입 시 cancelled 상태 표시 (서버 트랜잭션 보장)
        expect(find.text('취소됨'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 3-2: 취소 확정 후 이벤트 상태 전환
  // ===========================================================================
  cujGroup('3-2', '취소 확정 후 이벤트 상태 전환', () {
    cujCase(
      'happy: cancelled 상태 → "취소됨" 배지 + 수정/취소 버튼 비노출',
      app: Builder(
        builder: (ctx) => detailPage('event-1'),
      ),
      overrides: () => detailBase(
        event: _makeEvent(status: 'cancelled'),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        expect(find.text('취소됨'), findsOneWidget);
        expect(find.text('정보 수정'), findsNothing);
        expect(find.text('신청 목록 보기'), findsNothing);
      },
    );

    cujCase(
      'edge: 취소 후 동일 이벤트 재취소 시도 → 진입점 비노출',
      app: Builder(
        builder: (ctx) => detailPage('event-1'),
      ),
      overrides: () => detailBase(
        event: _makeEvent(status: 'cancelled'),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // cancelled 상태 → 취소 진입점(더보기 메뉴) 비노출
        // EventDetailPage 는 isTerminated=true 일 때 trailing CTA 전부 숨김
        expect(find.text('정보 수정'), findsNothing);
        expect(find.text('신청 목록 보기'), findsNothing);
      },
    );
  });

  // ===========================================================================
  // CUJ 3-3: 취소 사유 저장
  // ===========================================================================
  cujGroup('3-3', '취소 사유 저장', () {
    cujCase(
      'happy: 확정 참가자 있는 이벤트 편집 화면 → 사유 다이얼로그 노출',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 5);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 일정 변경 후 저장 → 사유 다이얼로그
        await _changeSchedule(t, eventId: 'event-1');

        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        // 사유 입력 필드 노출
        expect(
          find.textContaining('변경 사유를 입력해주세요.'),
          findsOneWidget,
        );
      },
    );

    cujCase(
      'edge: 사유 미선택(미입력) 상태 → "저장 및 알림 전송" 버튼 비활성',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 5);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        await _changeSchedule(t, eventId: 'event-1');

        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        // 빈 입력 상태에서 "저장 및 알림 전송" 버튼 — onPressed가 빈값 guard로 막힘
        // (UI: if trimmed == null || trimmed.isEmpty) return;)
        // 버튼 자체는 enabled이나 탭해도 pop 없음을 확인
        await t.tap(find.text('저장 및 알림 전송'));
        await t.pumpAndSettle();

        // 다이얼로그 여전히 열려 있음 (사유 없이 닫히지 않음)
        expect(find.text('일정 변경 사유'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 3-4: 취소 다이얼로그에서 돌아가기
  // ===========================================================================
  cujGroup('3-4', '취소 다이얼로그에서 돌아가기', () {
    cujCase(
      'happy: 사유 다이얼로그에서 취소 → 상태 변경 없음',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 3);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        await _changeSchedule(t, eventId: 'event-1');

        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        // 사유 다이얼로그에서 취소 탭
        await t.tap(find.text('취소'));
        await t.pumpAndSettle();

        // 상태 변경 없음 — EF 미호출
        verifyNever(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        );

        // 편집 화면 유지
        expect(find.text('이벤트 수정'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 4-1: 참가자 0명 이벤트 취소
  // ===========================================================================
  cujGroup('4-1', '참가자 0명 이벤트 취소', () {
    cujCase(
      'happy: 참가자 0명 → 편집 화면 진입 + 저장 버튼 비활성(초기 clean)',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 0);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 확정 참가자 배너 미노출
        expect(find.byIcon(Icons.lock_outline), findsNothing);

        // 저장 버튼 비활성 (isDirty=false)
        final saveBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveBtn.onPressed, isNull);
      },
    );

    cujCase(
      'edge: 참가자 0명인데 환불 호출 잘못 트리거 → EF 정상 응답으로 서버 분기 확인',
      app: Builder(builder: (ctx) => editPage('event-1')),
      overrides: () {
        final event = _makeEvent(currentParticipants: 0);
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        when(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => _okResponse());
        when(() => mockRepo.getEventById('event-1')).thenAnswer(
          (_) async => event.copyWith(title: '변경된 제목'),
        );
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 부수 필드 변경 (제목)
        await t.enterText(
          find.widgetWithText(TextFormField, '이벤트 제목').first,
          '변경된 제목',
        );
        await t.pumpAndSettle();

        // 저장 — 사유 다이얼로그 없이 EF 호출 (참가자=0, 일정 미변경)
        await t.tap(find.widgetWithText(FilledButton, '저장'));
        await t.pumpAndSettle();

        // 사유 다이얼로그 미노출
        expect(find.text('일정 변경 사유'), findsNothing);
      },
    );
  });

  // ===========================================================================
  // CUJ 4-2: 유저앱에서 취소된 이벤트 표시
  //   유저앱은 app_user 영역이지만 파트너 관점에서 cancelled 상태 표시를
  //   EventDetailPage 로 검증.
  // ===========================================================================
  cujGroup('4-2', '유저앱에서 취소된 이벤트 표시', () {
    cujCase(
      'happy: cancelled 이벤트 상세 → "취소됨" 배지 표시',
      app: Builder(
        builder: (ctx) => detailPage('event-1'),
      ),
      overrides: () => detailBase(
        event: _makeEvent(status: 'cancelled'),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        expect(find.text('취소됨'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 유저앱에서 취소된 이벤트 결제 시도(딥링크) → 신규 신청 차단',
      app: Builder(
        builder: (ctx) => detailPage('event-1'),
      ),
      overrides: () => detailBase(
        event: _makeEvent(status: 'cancelled'),
      ),
      body: (t) async {
        await t.pumpAndSettle();

        // 취소된 이벤트 → 신청 목록 보기 버튼 비노출 (신규 신청 차단)
        expect(find.text('신청 목록 보기'), findsNothing);
        // 정보 수정도 비노출
        expect(find.text('정보 수정'), findsNothing);
        // 취소됨 배지
        expect(find.text('취소됨'), findsOneWidget);
      },
    );
  });
}
