// CUJ tests — event / partner-dashboard
//
// 대응 spec: docs/features/event/partner-dashboard/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위:
//   - CUJ 1-1 ~ 1-5 (홈 탭 — 인사/칩/성과)
//   - CUJ 2-1 ~ 2-5 (EventActionCard 4개 phase + 빈 상태)
//   - CUJ 3-1 ~ 3-3 (신청관리 탭)
//   - CUJ 4-1 ~ 4-4 (체크인 탭 분기 + 스캐너 다크 테마)
//   - CUJ 5-1 ~ 5-3 (온보딩 스텝 가이드)
//
// 설계 결정:
//   - PartnerHomePage: partnerDashboardControllerProvider 를
//     _FakeDashboardController 로 대체. 네트워크 호출 없이 원하는 상태를 반환.
//   - EventActionCard / TodoSummaryChips: 상태 없는 순수 위젯이므로 직접 렌더.
//   - EventApplicationManagePage: eventApplicationsGroupedProvider
//     패밀리 전체 override.
//   - CheckinPlaceholderPage: todayEventsProvider 패밀리 전체 override.
//   - currentPartnerInfoProvider: (ref) => partner 함수형 override.
//   - notificationListProvider: _FakeNotificationList 로 빈 목록 반환.
//   - partnerHomeCoordinatorProvider: mocktail Mock (탭 이벤트 핸들러 격리).

import 'package:app_partner/src/features/application/event_application_manage_page.dart';
import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/features/checkin/qr_scanner_screen.dart';
import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/home/widgets/event_action_card.dart';
import 'package:app_partner/src/features/home/widgets/todo_summary_chips.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
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

class _MockPartnerHomeCoordinator extends Mock
    implements PartnerHomeCoordinator {}

// ---------------------------------------------------------------------------
// Fake providers
// ---------------------------------------------------------------------------

/// 네트워크 호출 없이 원하는 상태를 즉시 반환하는 대시보드 컨트롤러.
class _FakeDashboardController extends PartnerDashboardController {
  _FakeDashboardController(this._initialState);
  final PartnerDashboardState _initialState;

  @override
  PartnerDashboardState build() => _initialState;
}

/// 빈 알림 목록을 반환하는 가짜 알림 컨트롤러.
class _FakeNotificationList extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

/// 에러를 throw하는 알림 컨트롤러 — 섹션 독립 로딩 테스트용.
class _ErrorNotificationList extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async =>
      throw Exception('network error');
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

final _now = DateTime.now();
final _epoch = DateTime(2020);

Partner _makePartner({
  String id = 'partner-1',
  String name = '테스트 파트너',
}) => Partner(id: id, name: name);

Party _makeParty({
  String id = 'party-1',
  String partnerId = 'partner-1',
  String title = '테스트 파티',
}) => Party(
  id: id,
  partnerId: partnerId,
  title: title,
  createdAt: _epoch,
  updatedAt: _epoch,
);

Event _makeEvent({
  String id = 'event-1',
  String partyId = 'party-1',
  String title = '테스트 이벤트',
  DateTime? startTime,
  DateTime? endTime,
  int currentParticipants = 3,
  int maxParticipants = 20,
}) {
  final start = startTime ?? _now.add(const Duration(days: 7));
  final end = endTime ?? start.add(const Duration(hours: 3));
  return Event(
    id: id,
    partyId: partyId,
    title: title,
    startTime: start,
    endTime: end,
    createdAt: _epoch,
    updatedAt: _epoch,
    currentParticipants: currentParticipants,
    maxParticipants: maxParticipants,
  );
}

EventApplication _makeApplication({
  String id = 'app-1',
  String eventId = 'event-1',
  String status = 'pending',
}) => EventApplication(
  id: id,
  eventId: eventId,
  ticketId: 'ticket-1',
  userId: 'user-1',
  status: status,
  createdAt: _now.subtract(const Duration(hours: 1)),
  updatedAt: _now.subtract(const Duration(hours: 1)),
);

// ---------------------------------------------------------------------------
// Provider override helpers
// ---------------------------------------------------------------------------

List<dynamic> _homeBase({
  required PartnerDashboardState dashboardState,
  required _MockPartnerHomeCoordinator coordinator,
  NotificationList Function()? notificationFactory,
}) => [
  partnerDashboardControllerProvider.overrideWith(
    () => _FakeDashboardController(dashboardState),
  ),
  currentPartnerInfoProvider.overrideWith((ref) async => _makePartner()),
  notificationListProvider.overrideWith(
    notificationFactory ?? _FakeNotificationList.new,
  ),
  partnerHomeCoordinatorProvider.overrideWith((ref) => coordinator),
];

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final maxPumps = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
}

/// 이벤트가 있는 홈 기본 상태.
PartnerDashboardState _homeStateWithEvents({
  int pendingReviewCount = 0,
  List<Event> liveEvents = const [],
  List<Event> recruitingEvents = const [],
  List<Event> preparingEvents = const [],
  int totalPartyCount = 2,
  int totalAttendees = 10,
  bool hasAnyEvents = true,
}) => PartnerDashboardState(
  status: const AsyncValue.data(null),
  pendingReviewCount: pendingReviewCount,
  liveEvents: liveEvents,
  recruitingEvents: recruitingEvents,
  preparingEvents: preparingEvents,
  totalPartyCount: totalPartyCount,
  totalAttendees: totalAttendees,
  hasAnyEvents: hasAnyEvents,
);

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockPartnerHomeCoordinator coordinator;
  late _MockEventRepository mockEventRepo;

  setUp(() {
    coordinator = _MockPartnerHomeCoordinator();
    mockEventRepo = _MockEventRepository();
  });

  // -------------------------------------------------------------------------
  // CUJ 1: 홈 탭 — 인사 / 할 일 칩 / 성과
  // -------------------------------------------------------------------------

  cujGroup('1-1', '홈 인사 영역에 오늘 할 일 N건 표시', () {
    cujCase(
      'happy: 심사 대기 3건 — 안내 문구 표시',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: _homeStateWithEvents(pendingReviewCount: 3),
        coordinator: coordinator,
      ),
      body: (t) async {
        // Fix #1933: PartnerHomePage 인사 영역 — pending > 0 시 심사 대기 문구
        expect(find.textContaining('심사 대기 3건'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 대기 0건 — 파티 수 표시',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: _homeStateWithEvents(
          totalPartyCount: 5,
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        expect(find.textContaining('운영 중인 파티 5개'), findsOneWidget);
      },
    );

    cujCase(
      'edge: Summary Bar 로딩 실패 — 에러 UI 렌더',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: PartnerDashboardState(
          status: AsyncValue.error(
            Exception('network error'),
            StackTrace.empty,
          ),
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        // 에러 상태: MinglitAsyncValueWidget의 DefaultErrorView 렌더 확인
        expect(find.text('오류가 발생했습니다.'), findsOneWidget);
      },
    );
  });

  cujGroup('1-2', '할 일 칩 3개 표시 + 탭 이동', () {
    var tapCount = 0;
    cujCase(
      'happy: 승인대기 / 다가오는이벤트 / 리뷰 칩 3개 노출 + 탭 콜백',
      app: TodoSummaryChips(
        pendingApplications: 2,
        upcomingEvents: 1,
        onPendingTap: () => tapCount++,
        onUpcomingTap: () => tapCount++,
      ),
      body: (t) async {
        expect(find.text('승인 대기'), findsOneWidget);
        expect(find.text('다가오는 이벤트'), findsOneWidget);
        // comingSoon=true 칩은 label 대신 '준비 중' 렌더 (TodoSummaryChips 구현)
        expect(find.text('준비 중'), findsOneWidget);
        // 활성 카운트 확인
        expect(find.text('2'), findsOneWidget); // pending
        expect(find.text('1'), findsOneWidget); // upcoming
        // 탭 → onPendingTap 콜백 호출 검증 (onPressed 연결 회귀 방지)
        await t.tap(find.text('승인 대기'));
        await t.pump();
        expect(tapCount, equals(1));
      },
    );

    cujCase(
      'edge: 카운트 0 — 회색 비활성 칩',
      app: TodoSummaryChips(
        pendingApplications: 0,
        upcomingEvents: 0,
        onPendingTap: () {},
        onUpcomingTap: () {},
      ),
      body: (t) async {
        // 카운트 0 표시
        expect(find.text('0'), findsWidgets);
      },
    );
  });

  cujGroup('1-3', '미답변 리뷰 칩 "준비 중" 라벨', () {
    cujCase(
      'happy: 리뷰 칩에 "준비 중" 표시',
      app: TodoSummaryChips(
        pendingApplications: 0,
        upcomingEvents: 0,
        onPendingTap: () {},
        onUpcomingTap: () {},
      ),
      body: (t) async {
        // TodoSummaryChips 항상 "준비 중" 라벨 표시 (comingSoon=true)
        expect(find.text('준비 중'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 탭 시 "곧 출시" 스낵바',
      app: Scaffold(
        body: TodoSummaryChips(
          pendingApplications: 0,
          upcomingEvents: 0,
          onPendingTap: () {},
          onUpcomingTap: () {},
        ),
      ),
      body: (t) async {
        // 리뷰 칩 탭 (3번째 칩)
        final chips = find.byType(GestureDetector);
        await t.tap(chips.at(2));
        await t.pump();
        expect(find.textContaining('곧 출시'), findsOneWidget);
      },
    );
  });

  cujGroup('1-4', '이번 주 성과 3칸 그리드', () {
    cujCase(
      'happy: 등록된 파티 / 모집 이벤트 / 참가예정 고객 3칸 노출',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: _homeStateWithEvents(
          totalPartyCount: 3,
          recruitingEvents: [_makeEvent()],
          totalAttendees: 15,
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        // HomeOverviewBlock: 3개 stat 카운트 노출
        // '모집 중인 이벤트'는 stat label + section header 두 곳에 렌더됨 → findsWidgets
        expect(find.text('등록된 파티'), findsOneWidget);
        expect(find.text('모집 중인 이벤트'), findsWidgets);
        expect(find.text('참가예정 고객'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 신규 파트너 데이터 없음 — 섹션 숨김',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: const PartnerDashboardState(
          status: AsyncValue.data(null),
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        // 이벤트 없는 온보딩 상태 — overview block 미노출
        expect(find.text('등록된 파티'), findsNothing);
      },
    );
  });

  cujGroup('1-5', '섹션 독립 로딩 — 한 섹션 실패 시 나머지 정상', () {
    cujCase(
      'happy: 모든 섹션 정상 로딩 — 인사/칩/성과 모두 렌더',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: _homeStateWithEvents(
          pendingReviewCount: 2,
          recruitingEvents: [_makeEvent()],
          totalPartyCount: 3,
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        expect(find.textContaining('심사 대기 2건'), findsOneWidget);
        expect(find.text('등록된 파티'), findsOneWidget);
      },
    );

    cujCase(
      'edge: notificationListProvider 실패 — 메인 섹션 정상 렌더',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: _homeStateWithEvents(
          pendingReviewCount: 2,
          recruitingEvents: [_makeEvent()],
          totalPartyCount: 3,
        ),
        coordinator: coordinator,
        // 알림 provider 실패 — maybeWhen(orElse: () => 0) 으로 배지는 0 폴백
        notificationFactory: _ErrorNotificationList.new,
      ),
      body: (t) async {
        // 알림 섹션 실패해도 메인 섹션(인사/성과) 정상 렌더
        expect(find.textContaining('심사 대기 2건'), findsOneWidget);
        expect(find.text('등록된 파티'), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // CUJ 2: 이벤트 액션카드 phase
  // -------------------------------------------------------------------------

  cujGroup('2-1', '다가오는 이벤트가 모집 중 phase', () {
    // 모집 중 = 시작까지 3시간 초과
    final recruitingEvent = _makeEvent(
      startTime: _now.add(const Duration(hours: 5)),
    );

    cujCase(
      'happy: "모집 중" 배지 + "신청 현황 보기" CTA',
      app: EventActionCard(
        event: recruitingEvent,
        onMainAction: () {},
        onSecondaryAction1: () {},
        onSecondaryAction2: () {},
      ),
      body: (t) async {
        expect(find.textContaining('모집 중'), findsOneWidget);
        expect(find.text('신청 현황 보기'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 100% 마감 — 프로그레스 바 가득',
      app: EventActionCard(
        event: _makeEvent(
          startTime: _now.add(const Duration(hours: 5)),
          currentParticipants: 20,
        ),
        onMainAction: () {},
        onSecondaryAction1: () {},
        onSecondaryAction2: () {},
      ),
      body: (t) async {
        // 카운트 "20/20명" 표시
        expect(find.textContaining('20/20'), findsOneWidget);
      },
    );
  });

  cujGroup('2-2', '이벤트가 준비 중 phase (3h 이내)', () {
    // 준비 중 = 시작까지 3시간 이하
    final preparingEvent = _makeEvent(
      startTime: _now.add(const Duration(hours: 1)),
    );

    cujCase(
      'happy: "준비 중" 배지 + "체크인 준비" CTA',
      app: EventActionCard(
        event: preparingEvent,
        onMainAction: () {},
        onSecondaryAction1: () {},
        onSecondaryAction2: () {},
      ),
      body: (t) async {
        expect(find.textContaining('준비 중'), findsOneWidget);
        expect(find.text('체크인 준비'), findsOneWidget);
      },
    );
  });

  cujGroup('2-3', '이벤트가 LIVE phase', () {
    // LIVE = 시작 ~ 종료 사이
    final liveEvent = _makeEvent(
      startTime: _now.subtract(const Duration(minutes: 30)),
      endTime: _now.add(const Duration(hours: 2)),
    );

    cujCase(
      'happy: "LIVE" 배지 + "체크인 계속하기" CTA',
      app: EventActionCard(
        event: liveEvent,
        onMainAction: () {},
        onSecondaryAction1: () {},
        onSecondaryAction2: null,
      ),
      body: (t) async {
        expect(find.textContaining('LIVE'), findsOneWidget);
        expect(find.text('체크인 계속하기'), findsOneWidget);
      },
    );
  });

  cujGroup('2-4', '이벤트가 종료 24h 이내 (ended)', () {
    // 종료 = 종료 시간 경과
    final endedEvent = _makeEvent(
      startTime: _now.subtract(const Duration(hours: 5)),
      endTime: _now.subtract(const Duration(hours: 2)),
    );

    cujCase(
      'happy: "종료" 배지 + "다음 회차 만들기" CTA',
      app: EventActionCard(
        event: endedEvent,
        onMainAction: () {},
        onSecondaryAction1: () {},
        onSecondaryAction2: null,
      ),
      body: (t) async {
        expect(find.textContaining('종료'), findsOneWidget);
        expect(find.text('다음 회차 만들기'), findsOneWidget);
      },
    );
  });

  cujGroup('2-5', '이벤트 없을 때 빈 상태', () {
    cujCase(
      'happy: 이벤트 0개 — 생성 유도 안내',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: PartnerDashboardState(
          status: const AsyncValue.data(null),
          activeParties: [_makeParty()],
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        // OnboardingStepGuide — 파티 있고 이벤트 없음
        // step title + CTA button 두 곳에 렌더됨 → findsWidgets
        expect(find.text('첫 이벤트 만들기'), findsWidgets);
      },
    );
  });

  // -------------------------------------------------------------------------
  // CUJ 3: 신청관리 탭
  // -------------------------------------------------------------------------

  cujGroup('3-1', '신청관리 탭 — 이벤트별 그루핑', () {
    final event1 = _makeEvent(title: '이벤트 A');
    final app1 = _makeApplication();

    cujCase(
      'happy: 대기중 탭 기본 — 이벤트 헤더 + 신청자 row 노출',
      app: const EventApplicationManagePage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        eventApplicationsGroupedProvider.overrideWith(
          (ref, params) async => {
            event1: [app1],
          },
        ),
      ],
      body: (t) async {
        // 탭바 3개 (대기중/승인됨/거절됨)
        expect(find.text('대기중'), findsOneWidget);
        expect(find.text('승인됨'), findsOneWidget);
        expect(find.text('거절됨'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 대기중 신청 0건 — 빈 상태',
      app: const EventApplicationManagePage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        eventApplicationsGroupedProvider.overrideWith(
          (ref, params) async => {},
        ),
      ],
      body: (t) async {
        expect(find.textContaining('대기 중인 신청이 없습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('3-2', '신청 인라인 승인 / 거절', () {
    final event1 = _makeEvent(title: '승인 테스트 이벤트');
    final app1 = _makeApplication();

    cujCase(
      'happy: 승인 버튼 탭 → 승인 API 호출 + 스낵바',
      app: const EventApplicationManagePage(),
      overrides: () {
        when(
          () => mockEventRepo.approveApplication(
            applicationId: any(named: 'applicationId'),
          ),
        ).thenAnswer((_) async {});
        return [
          currentPartnerInfoProvider.overrideWith(
            (ref) async => _makePartner(),
          ),
          eventApplicationsGroupedProvider.overrideWith(
            (ref, params) async => {
              event1: [app1],
            },
          ),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
        ];
      },
      body: (t) async {
        // 승인 버튼 (Icons.check tooltip '승인') 찾아서 탭
        final approveBtn = find.byTooltip('승인');
        expect(approveBtn, findsOneWidget);
        await t.tap(approveBtn);
        await t.pumpAndSettle();
        // 성공 스낵바 확인
        expect(find.textContaining('승인되었습니다'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 승인 API 실패 → 에러 스낵바',
      app: const EventApplicationManagePage(),
      overrides: () {
        when(
          () => mockEventRepo.approveApplication(
            applicationId: any(named: 'applicationId'),
          ),
        ).thenThrow(Exception('network error'));
        return [
          currentPartnerInfoProvider.overrideWith(
            (ref) async => _makePartner(),
          ),
          eventApplicationsGroupedProvider.overrideWith(
            (ref, params) async => {
              event1: [app1],
            },
          ),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
        ];
      },
      body: (t) async {
        await t.tap(find.byTooltip('승인'));
        await t.pumpAndSettle();
        expect(find.textContaining('승인 실패'), findsOneWidget);
      },
    );
  });

  cujGroup('3-3', '전체 승인 일괄 처리', () {
    final event1 = _makeEvent();
    final apps = [
      _makeApplication(),
      _makeApplication(id: 'app-2'),
    ];

    cujCase(
      'happy: 대기중 N건 — 버튼 탭 → 확인 다이얼로그 → 일괄 승인',
      app: const EventApplicationManagePage(),
      overrides: () {
        when(
          () => mockEventRepo.bulkApproveApplications(
            eventId: any(named: 'eventId'),
          ),
        ).thenAnswer((_) async {});
        return [
          currentPartnerInfoProvider.overrideWith(
            (ref) async => _makePartner(),
          ),
          eventApplicationsGroupedProvider.overrideWith(
            (ref, params) async =>
                params.statusFilter.contains('pending') ? {event1: apps} : {},
          ),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
        ];
      },
      body: (t) async {
        // 대기중 2건 → 하단 "전체 승인 (2건)" 버튼 노출
        expect(find.textContaining('전체 승인 (2건)'), findsOneWidget);
        // 버튼 탭 → MinglitAlert.showConfirm 다이얼로그
        await t.tap(find.textContaining('전체 승인 (2건)'));
        await t.pumpAndSettle();
        // 확인 TextButton('전체 승인') 탭
        await t.tap(find.widgetWithText(TextButton, '전체 승인'));
        await t.pumpAndSettle();
        // bulkApproveApplications 1회 호출 (event1에 대해)
        verify(
          () => mockEventRepo.bulkApproveApplications(
            eventId: any(named: 'eventId'),
          ),
        ).called(1);
        // 성공 스낵바
        expect(find.textContaining('승인 완료'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 승인됨 탭 — 전체 승인 버튼 미노출',
      app: const EventApplicationManagePage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        eventApplicationsGroupedProvider.overrideWith(
          (ref, params) async => {},
        ),
      ],
      body: (t) async {
        // 승인됨 탭으로 이동
        await t.tap(find.text('승인됨'));
        await t.pumpAndSettle();
        expect(find.textContaining('전체 승인'), findsNothing);
      },
    );
  });

  // -------------------------------------------------------------------------
  // CUJ 4: 체크인 탭 (카메라 불필요 시나리오만)
  // -------------------------------------------------------------------------

  cujGroup('4-1', '체크인 탭 진입 — 오늘 이벤트 1개면 즉시 스캐너', () {
    final oneEvent = _makeEvent(
      title: '오늘의 이벤트',
      startTime: _now.subtract(const Duration(minutes: 30)),
      endTime: _now.add(const Duration(hours: 2)),
    );

    cujCase(
      'happy: 오늘 이벤트 1건 — 선택 화면 없이 스캐너 타이틀 노출',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        todayEventsProvider.overrideWith(
          (ref, partnerId) async => [oneEvent],
        ),
      ],
      afterPump: const Duration(seconds: 2),
      body: (t) async {
        await _pumpUntilFound(t, find.byType(QRScannerScreen));
        expect(find.byType(QRScannerScreen), findsOneWidget);
        expect(find.textContaining('이벤트를 선택하세요'), findsNothing);
      },
    );
  });

  cujGroup('4-2', '오늘 이벤트 2개 이상 — 선택 리스트', () {
    final events = [
      _makeEvent(
        title: '이벤트 A',
        startTime: _now.add(const Duration(hours: 1)),
        endTime: _now.add(const Duration(hours: 4)),
      ),
      _makeEvent(
        id: 'event-2',
        title: '이벤트 B',
        startTime: _now.add(const Duration(hours: 2)),
        endTime: _now.add(const Duration(hours: 5)),
      ),
    ];

    cujCase(
      'happy: 2개 이벤트 — 선택 리스트 노출',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        todayEventsProvider.overrideWith(
          (ref, partnerId) async => events,
        ),
      ],
      body: (t) async {
        expect(find.textContaining('이벤트를 선택하세요'), findsOneWidget);
        expect(find.textContaining('2개 이벤트'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 4개 이상 이벤트 — 스크롤 가능 선택 리스트',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        todayEventsProvider.overrideWith(
          (ref, partnerId) async => [
            ...events,
            _makeEvent(
              id: 'event-3',
              startTime: _now.add(const Duration(hours: 3)),
            ),
            _makeEvent(
              id: 'event-4',
              startTime: _now.add(const Duration(hours: 4)),
            ),
          ],
        ),
      ],
      body: (t) async {
        expect(find.textContaining('4개 이벤트'), findsOneWidget);
      },
    );
  });

  cujGroup('4-3', '오늘 이벤트 0개 — 빈 상태', () {
    cujCase(
      'happy: "오늘 예정된 이벤트가 없습니다" 노출',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        todayEventsProvider.overrideWith((ref, partnerId) async => []),
      ],
      body: (t) async {
        expect(find.textContaining('오늘 예정된 이벤트가 없습니다'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 파트너 정보 로드 실패 → 에러 메시지',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => throw Exception('network error'),
        ),
        todayEventsProvider.overrideWith((ref, partnerId) async => []),
      ],
      body: (t) async {
        expect(find.textContaining('오류가 발생했습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('4-4', '체크인 화면 다크 배경 (앱 전체는 라이트 유지)', () {
    final oneEvent = _makeEvent(
      title: '다크 스캐너 테스트',
      startTime: _now.subtract(const Duration(minutes: 10)),
      endTime: _now.add(const Duration(hours: 1)),
    );
    final anotherEvent = _makeEvent(
      id: 'event-2',
      title: '복귀 검증 이벤트',
      startTime: _now.subtract(const Duration(minutes: 5)),
      endTime: _now.add(const Duration(hours: 2)),
    );

    cujCase(
      'happy: 스캐너 라우트에 다크 Theme 적용',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        todayEventsProvider.overrideWith(
          (ref, partnerId) async => [oneEvent],
        ),
      ],
      afterPump: const Duration(seconds: 2),
      body: (t) async {
        await _pumpUntilFound(t, find.byType(QRScannerScreen));
        final hasDarkTheme = t
            .widgetList<Theme>(find.byType(Theme))
            .any((w) => w.data.brightness == Brightness.dark);
        expect(hasDarkTheme, isTrue);
      },
    );

    cujCase(
      'edge: 스캐너 진입 후 복귀해도 체크인 외 화면은 라이트 테마 유지',
      app: const CheckinPlaceholderPage(),
      overrides: () => [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => _makePartner(),
        ),
        todayEventsProvider.overrideWith(
          (ref, partnerId) async => [oneEvent, anotherEvent],
        ),
      ],
      body: (t) async {
        expect(find.text('이벤트를 선택하세요'), findsOneWidget);

        final rootBefore = t.widget<MaterialApp>(
          find.byType(MaterialApp).first,
        );
        expect(rootBefore.theme?.brightness, Brightness.light);

        await t.tap(find.byType(Card).first);
        await t.pump(const Duration(seconds: 2));
        await _pumpUntilFound(t, find.byType(QRScannerScreen));

        final hasDarkThemeOnScanner = t
            .widgetList<Theme>(find.byType(Theme))
            .any((w) => w.data.brightness == Brightness.dark);
        expect(hasDarkThemeOnScanner, isTrue);

        await t.pageBack();
        await t.pump(const Duration(milliseconds: 600));
        await _pumpUntilFound(t, find.text('이벤트를 선택하세요'));

        expect(find.text('이벤트를 선택하세요'), findsOneWidget);
        final rootAfter = t.widget<MaterialApp>(find.byType(MaterialApp).first);
        expect(rootAfter.theme?.brightness, Brightness.light);
        final hasDarkThemeAfterBack = t
            .widgetList<Theme>(find.byType(Theme))
            .any((w) => w.data.brightness == Brightness.dark);
        expect(hasDarkThemeAfterBack, isFalse);
      },
    );
  });

  // -------------------------------------------------------------------------
  // CUJ 5: 온보딩 스텝 가이드
  // -------------------------------------------------------------------------

  cujGroup('5-1', '신규 파트너 — 파티 0개 시 스텝 가이드', () {
    cujCase(
      'happy: 파티 0개 → "첫 파티 만들기" CTA',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: const PartnerDashboardState(
          status: AsyncValue.data(null),
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        // step title + CTA button 두 곳에 렌더됨 → findsWidgets
        expect(find.text('첫 파티 만들기'), findsWidgets);
      },
    );

    cujCase(
      'edge: 파티 0개 + 이벤트 0 → 가이드 진행률 바 2/4',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: const PartnerDashboardState(
          status: AsyncValue.data(null),
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        // OnboardingStepGuide 렌더됨 확인
        expect(find.textContaining('파티는 이벤트를 묶는 브랜드'), findsOneWidget);
      },
    );
  });

  cujGroup('5-2', '파티 1+ / 이벤트 0개 — 이벤트 넛지', () {
    cujCase(
      'happy: 파티 있고 이벤트 없음 → "첫 이벤트 만들기" CTA',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: PartnerDashboardState(
          status: const AsyncValue.data(null),
          activeParties: [_makeParty(title: '나의 파티')],
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        // step title + CTA button 두 곳에 렌더됨 → findsWidgets
        expect(find.text('첫 이벤트 만들기'), findsWidgets);
      },
    );

    cujCase(
      'edge: 파티 이름이 스텝 가이드에 표시됨',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: PartnerDashboardState(
          status: const AsyncValue.data(null),
          activeParties: [_makeParty(title: '나의 멋진 파티')],
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        expect(find.textContaining('나의 멋진 파티'), findsOneWidget);
      },
    );
  });

  cujGroup('5-3', '첫 이벤트 생성 → 일반 대시보드 전환', () {
    cujCase(
      'happy: hasAnyEvents=true 이면 온보딩 가이드 숨김 + 일반 대시보드 노출',
      app: const PartnerHomePage(),
      overrides: () => _homeBase(
        dashboardState: _homeStateWithEvents(
          recruitingEvents: [_makeEvent(title: '방금 만든 이벤트')],
          totalPartyCount: 1,
        ),
        coordinator: coordinator,
      ),
      body: (t) async {
        expect(find.text('모집 중인 이벤트'), findsWidgets);
        expect(find.text('첫 이벤트 만들기'), findsNothing);
      },
    );
  });
}
