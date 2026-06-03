// CUJ tests — event / refund-policy-v2
//
// 대응 spec: docs/features/event/refund-policy-v2/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위:
//   - CUJ 1-1: grace period(3시간) 내 자동 환불 (P0)
//   - CUJ 1-2: grace period 내 다이얼로그에서 돌아가기 (P0)
//   - CUJ 1-3: 환불 완료 후 라벨 표시 (P1)
//   - CUJ 1-4: 구매 내역 리스트 카드에서 상세 진입 (P0)
//   - CUJ 5-2: 무료 이벤트 취소 (P0)
//
// 설계 결정:
//   - PurchaseHistoryDetailPage 를 직접 렌더 (purchaseHistoryDetailProvider 주입).
//   - purchaseHistoryDetailProvider(applicationId) 를 overrideWith 로 주입하면
//     캐시 탐색 체인(purchaseHistoryControllerProvider) 을 우회.
//   - purchaseHistoryControllerProvider.notifier.canCancel() 는 동기 순수 함수.
//     notifier 생성에 currentUserProvider + eventRepositoryProvider 가
//     필요하므로 base()에 포함.
//   - policyRepositoryProvider 는 mock 없이 두고 catch 블록이 기본값(2h/7d)을 사용하도록 함.
//   - cancelOrder EF 호출은 eventRepositoryProvider mock 으로 격리.

import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/payment/logic/'
    'purchase_history_detail_controller.dart';
import 'package:app_user/src/features/payment/ui/'
    'purchase_history_detail_page.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockEventRepository extends Mock implements EventRepository {}

class _MockUser extends Mock implements User {}

class _MockPolicyRepository extends Mock implements PolicyRepository {}

class _MockGoRouter extends Mock implements GoRouter {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

late _MockGoRouter _mockRouter;

Widget _withFakeRouter(Widget child) {
  return _FakeRouterScope(child: child);
}

class _FakeRouterScope extends StatelessWidget {
  const _FakeRouterScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InheritedGoRouter(goRouter: _mockRouter, child: child);
  }
}

final _now = DateTime.now();

Event _makeEvent({
  String id = 'event-1',
  String status = 'scheduled',
  DateTime? startTime,
  Party? party,
}) {
  return Event(
    id: id,
    partyId: 'party-1',
    title: '테스트 이벤트',
    startTime: startTime ?? _now.add(const Duration(days: 30)),
    endTime: _now.add(const Duration(days: 30, hours: 2)),
    createdAt: _now,
    updatedAt: _now,
    status: status,
    party: party,
    tickets: const [],
    entryGroups: const [],
  );
}

EventApplication _makeApplication({
  String id = 'app-1',
  String status = 'paid',
  int? paymentAmount = 50000,
  String? paymentId = 'pay-1',
  String refundStatus = 'none',
  DateTime? paidAt,
  DateTime? eventStartTime,
  Party? eventParty,
}) {
  return EventApplication(
    id: id,
    eventId: 'event-1',
    ticketId: 'ticket-1',
    userId: 'user-1',
    status: status,
    paymentId: paymentId,
    paymentAmount: paymentAmount,
    refundStatus: refundStatus,
    paidAt: paidAt ?? _now.subtract(const Duration(minutes: 30)),
    createdAt: _now,
    updatedAt: _now,
    event: _makeEvent(startTime: eventStartTime, party: eventParty),
    ticket: Ticket(
      id: 'ticket-1',
      name: '일반 입장권',
      price: paymentAmount ?? 0,
      createdAt: _now,
      updatedAt: _now,
    ),
  );
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockEventRepository mockRepo;
  late _MockUser mockUser;
  late _MockPolicyRepository mockPolicyRepo;

  setUp(() {
    mockRepo = _MockEventRepository();
    mockUser = _MockUser();
    mockPolicyRepo = _MockPolicyRepository();
    _mockRouter = _MockGoRouter();
    when(() => mockUser.id).thenReturn('user-1');
    when(
      () => _mockRouter.push<void>(
        any(),
        extra: any(named: 'extra'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockRepo.getMyPurchaseHistory(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepo.getEntryGroupParticipantCounts(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockPolicyRepo.getRefundPolicy(),
    ).thenAnswer((_) async => {'grace_period_hours': 3, 'cutoff_days': 7});
  });

  // base overrides: controller notifier 생성에 필요한 최소 세트.
  List<dynamic> base() => [
    currentUserProvider.overrideWith((_) => mockUser),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    eventRepositoryProvider.overrideWithValue(mockRepo),
    policyRepositoryProvider.overrideWithValue(mockPolicyRepo),
  ];

  // Returns overrides for PurchaseHistoryDetailPage rendering with the
  // given application.
  List<dynamic> withApp(EventApplication app) => [
    purchaseHistoryDetailProvider(app.id).overrideWith((_) async => app),
    ...base(),
  ];

  // Returns overrides for EventDetailPage rendering with fixed now().
  List<dynamic> withEventDetail({required DateTime now}) => [
    currentUserProvider.overrideWith((_) => null),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    eventRepositoryProvider.overrideWithValue(mockRepo),
    policyRepositoryProvider.overrideWithValue(mockPolicyRepo),
    eventDetailNowProvider.overrideWith(
      (_) =>
          () => now,
    ),
  ];

  Future<void> scrollToRefundPolicy(WidgetTester t) async {
    await t.scrollUntilVisible(
      find.byTooltip('환불 정책 상세'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await t.pumpAndSettle();
  }

  // ===========================================================================
  // CUJ 1-1: grace period(3시간) 내 자동 환불
  // ===========================================================================
  cujGroup('1-1', 'grace period(3시간) 내 자동 환불', () {
    cujCase(
      'happy: 결제 30분 후 상세 진입 → 예매 취소 버튼 활성',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-1'),
      overrides: () {
        final app = _makeApplication(
          paidAt: _now.subtract(const Duration(minutes: 30)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 예매 취소 버튼 활성 (canCancel=true)
        final cancelBtn = t.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '예매 취소'),
        );
        expect(cancelBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'happy: 결제 확인 다이얼로그 → 취소하기 → cancelOrder 호출',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-1'),
      overrides: () {
        final app = _makeApplication(
          paidAt: _now.subtract(const Duration(minutes: 30)),
        );
        when(
          () => mockRepo.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        ).thenAnswer(
          (_) async =>
              const CancelOrderResult(type: 'refunded', refundAmount: 50000),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // Fix #2589 dev-blocker: PurchaseHistoryDetailPage SingleChildScroll
        // View 가 viewport(866px)보다 커서 예매 취소 버튼이 off-screen
        // → tap miss (Offset Y=908 > 866). ensureVisible로 스크롤 후 탭.
        await t.ensureVisible(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pump();
        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        // 확인 다이얼로그 표시 (FR-2: 환불 금액 안내)
        expect(find.text('예매 취소'), findsWidgets);
        expect(find.textContaining('원이 환불됩니다'), findsOneWidget);

        final messenger = ScaffoldMessenger.maybeOf(
          t.element(find.byType(PurchaseHistoryDetailPage)),
        );

        // "취소하기" 탭 → cancelOrder 호출
        await t.tap(find.text('취소하기'));
        await t.pumpAndSettle();

        verify(
          () => mockRepo.cancelOrder(
            eventId: 'event-1',
            reason: any(named: 'reason'),
          ),
        ).called(1);

        // Fix #2589 dev-blocker: onSuccess() 의 showMinglitSuccess SnackBar 는
        // 3 초 후 자동 dismiss Timer 가 있다. pumpAndSettle 은 Timer 를 drain 하지
        // 않으므로 test body 종료 후 Timer 가 발화 → flutter_test binding 의
        // 'inTest: is not true' assertion. test 끝나기 전에 명시적으로 clear.
        messenger?.clearSnackBars();
        await t.pumpAndSettle();
      },
    );

    cujCase(
      'edge: 이벤트 시작 후 → 예매 취소 버튼 비활성 (eventNotStarted=false)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-2'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-2',
          paidAt: _now.subtract(const Duration(minutes: 30)),
          eventStartTime: _now.subtract(const Duration(hours: 1)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // eventNotStarted=false → canCancel=false → 버튼 비활성
        final cancelBtn = t.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '예매 취소'),
        );
        expect(cancelBtn.onPressed, isNull);
      },
    );
  });

  // ===========================================================================
  // CUJ 1-2: grace period 내 다이얼로그에서 돌아가기
  // ===========================================================================
  cujGroup('1-2', 'grace period 내 다이얼로그에서 돌아가기', () {
    cujCase(
      'happy: 예매 취소 탭 → 다이얼로그 → 아니오 → 상태 유지',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-1'),
      overrides: () {
        final app = _makeApplication(
          paidAt: _now.subtract(const Duration(minutes: 30)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // Fix #2589 dev-blocker: 예매 취소 버튼 off-screen → ensureVisible 후 탭.
        await t.ensureVisible(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pump();
        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        // 다이얼로그 표시
        expect(find.text('예매 취소'), findsWidgets);

        // "아니오" 탭 → 다이얼로그 닫힘
        await t.tap(find.text('아니오'));
        await t.pumpAndSettle();

        // cancelOrder 미호출 (FR-2: 돌아가기 = 상태 변경 없음)
        verifyNever(
          () => mockRepo.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        );

        // 화면 유지 (예매 취소 버튼 여전히 노출)
        expect(find.widgetWithText(ElevatedButton, '예매 취소'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 1-3: 환불 완료 후 라벨 표시
  // ===========================================================================
  cujGroup('1-3', '환불 완료 후 라벨 표시', () {
    cujCase(
      'happy: refundStatus=completed → 예매 취소 버튼 비활성 + 환불 정보 섹션',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-1'),
      overrides: () {
        final app = _makeApplication(
          status: 'cancelled',
          refundStatus: 'completed',
          paidAt: _now.subtract(const Duration(minutes: 30)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // isRefunded=true → 취소 버튼 섹션 전체 미노출 (FR-1: 재취소 차단)
        expect(find.widgetWithText(ElevatedButton, '예매 취소'), findsNothing);

        // 환불 정보 섹션 노출 (isRefunded=true)
        expect(find.text('환불 정보'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 1-4: 구매 내역 리스트 카드에서 상세 진입
  // ===========================================================================
  cujGroup('1-4', '구매 내역 리스트 카드에서 상세 진입', () {
    cujCase(
      'happy: 리스트 카드에는 취소 액션이 없고 카드 탭은 상세 route를 push',
      app: _withFakeRouter(const PurchaseHistoryPage()),
      overrides: () {
        final app = _makeApplication(id: 'app-list');
        when(
          () => mockRepo.getMyPurchaseHistory('user-1'),
        ).thenAnswer((_) async => [app]);
        return base();
      },
      body: (t) async {
        expect(find.text('상세 보기'), findsOneWidget);
        expect(find.text('결제완료'), findsOneWidget);
        expect(find.text('영수증'), findsNothing);
        expect(find.text('문의하기'), findsNothing);
        expect(find.text('예매 취소'), findsNothing);

        await t.tap(find.byType(PurchaseHistoryCard));
        await t.pump();

        verify(
          () => _mockRouter.push<void>(
            '/purchase-history/app-list',
            extra: any(named: 'extra'),
          ),
        ).called(1);
      },
    );
  });

  // ===========================================================================
  // CUJ 2-1: cutoff(7일) 전 자동 환불
  // ===========================================================================
  cujGroup('2-1', 'cutoff(7일) 전 자동 환불', () {
    cujCase(
      'happy: grace 경과(4h) + cutoff 전(10d)에서도 취소 확정 시 cancelOrder 호출',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-cutoff'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-cutoff',
          paidAt: _now.subtract(const Duration(hours: 4)),
          eventStartTime: _now.add(const Duration(days: 10)),
        );
        when(
          () => mockRepo.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        ).thenAnswer(
          (_) async =>
              const CancelOrderResult(type: 'refunded', refundAmount: 50000),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();
        await t.ensureVisible(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pump();
        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        expect(find.textContaining('원이 환불됩니다'), findsOneWidget);

        final messenger = ScaffoldMessenger.maybeOf(
          t.element(find.byType(PurchaseHistoryDetailPage)),
        );

        await t.tap(find.text('취소하기'));
        await t.pumpAndSettle();

        verify(
          () => mockRepo.cancelOrder(
            eventId: 'event-1',
            reason: any(named: 'reason'),
          ),
        ).called(1);

        messenger?.clearSnackBars();
        await t.pumpAndSettle();
      },
    );
  });

  // ===========================================================================
  // CUJ 2-2: 결제 전 환불 정책 안내
  // ===========================================================================
  cujGroup('2-2', '결제 전 환불 정책 안내', () {
    cujCase(
      'happy: 이벤트 상세 info 버튼 탭 → 환불 정책 시트(3개 조건) 노출',
      app: const EventDetailPage(eventId: 'event-policy-sheet'),
      overrides: () {
        final event = _makeEvent(id: 'event-policy-sheet');
        when(
          () => mockRepo.getEventById('event-policy-sheet'),
        ).thenAnswer((_) async => event);
        return withEventDetail(now: _now);
      },
      body: (t) async {
        await t.pumpAndSettle();
        await scrollToRefundPolicy(t);

        expect(find.byTooltip('환불 정책 상세'), findsOneWidget);
        await t.tap(find.byTooltip('환불 정책 상세'));
        await t.pumpAndSettle();

        expect(find.text('환불 정책 상세'), findsOneWidget);
        expect(find.text('결제 후 3시간 이내'), findsOneWidget);
        expect(find.text('이벤트 시작 7일 전까지'), findsOneWidget);
        expect(find.text('그 외'), findsOneWidget);
        expect(find.text('고객센터 문의'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 2-3: 환불 정책 인라인 상태
  // ===========================================================================
  cujGroup('2-3', '환불 정책 인라인 상태', () {
    cujCase(
      'happy: cutoff 전 상태 → "~까지 환불 가능" 인라인 배너',
      app: const EventDetailPage(eventId: 'event-cutoff-open'),
      overrides: () {
        final event = _makeEvent(
          id: 'event-cutoff-open',
          startTime: DateTime(2026, 6, 10, 19),
        );
        when(
          () => mockRepo.getEventById('event-cutoff-open'),
        ).thenAnswer((_) async => event);
        return withEventDetail(now: DateTime(2026, 6, 1, 12));
      },
      body: (t) async {
        await t.pumpAndSettle();
        await scrollToRefundPolicy(t);

        expect(
          find.textContaining('까지 환불 가능', findRichText: true),
          findsOneWidget,
        );
        expect(find.textContaining('결제 후 3시간 이내에도 전액 환불 가능'), findsOneWidget);
      },
    );

    cujCase(
      'edge: cutoff 경과 상태 → grace 안내 + 자동 환불 불가(고객센터) 경로 노출',
      app: const EventDetailPage(eventId: 'event-cutoff-passed'),
      overrides: () {
        final event = _makeEvent(
          id: 'event-cutoff-passed',
          startTime: DateTime(2026, 6, 10, 19),
        );
        when(
          () => mockRepo.getEventById('event-cutoff-passed'),
        ).thenAnswer((_) async => event);
        return withEventDetail(now: DateTime(2026, 6, 5, 9));
      },
      body: (t) async {
        await t.pumpAndSettle();
        await scrollToRefundPolicy(t);

        expect(find.text('결제 후 3시간 이내 전액 환불 가능'), findsOneWidget);
        expect(find.text('이벤트 시작 7일 전 환불 마감'), findsOneWidget);

        await t.tap(find.byTooltip('환불 정책 상세'));
        await t.pumpAndSettle();
        expect(find.text('그 외'), findsOneWidget);
        expect(find.text('고객센터 문의'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 3-1: 자동 환불 불가 상태 안내
  // ===========================================================================
  cujGroup('3-1', '자동 환불 불가 상태 안내', () {
    cujCase(
      'edge: grace/cutoff 모두 경과 시 환불 기간 경고 + cancelOrder 미호출',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-expired'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-expired',
          paidAt: _now.subtract(const Duration(days: 3)),
          eventStartTime: _now.add(const Duration(days: 2)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();
        await t.ensureVisible(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pump();
        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        expect(find.text('환불 기간이 지났습니다.'), findsOneWidget);
        verifyNever(
          () => mockRepo.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        );
      },
    );
  });

  // ===========================================================================
  // CUJ 3-2: 환불 요청 상태 전환
  // ===========================================================================
  cujGroup('3-2', '환불 요청 상태 전환', () {
    cujCase(
      'happy: refundStatus=requested면 재요청 버튼 비활성',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-requested'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-requested',
          refundStatus: 'requested',
          paidAt: _now.subtract(const Duration(days: 1)),
          eventStartTime: _now.add(const Duration(days: 5)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();
        expect(find.text('환불 요청됨'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, '예매 취소'), findsNothing);
      },
    );
  });

  // ===========================================================================
  // CUJ 3-3: 환불 요청 결과 라벨
  // ===========================================================================
  cujGroup('3-3', '환불 요청 결과 라벨', () {
    cujCase(
      'happy: 환불 완료 상태에서 환불완료 라벨 노출',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-completed'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-completed',
          status: 'cancelled',
          refundStatus: 'completed',
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();
        expect(find.text('환불완료'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, '예매 취소'), findsNothing);
      },
    );
  });

  // ===========================================================================
  // CUJ 3-4: 미응답 상태 유지 시 재취소 차단
  // ===========================================================================
  cujGroup('3-4', '미응답 상태 유지 시 재취소 차단', () {
    cujCase(
      'edge: cancelled + requested 조합에서 추가 취소 액션 미노출',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-pending'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-pending',
          status: 'cancelled',
          refundStatus: 'requested',
          paidAt: _now.subtract(const Duration(days: 2)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();
        expect(find.widgetWithText(ElevatedButton, '예매 취소'), findsNothing);
      },
    );
  });

  // ===========================================================================
  // CUJ 5-1: 파트너 귀책 자동 환불
  // ===========================================================================
  cujGroup('5-1', '파트너 귀책 자동 환불', () {
    cujCase(
      'happy: cancelled + completed 상태는 환불 완료 UI로 즉시 반영',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-partner-fault'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-partner-fault',
          status: 'cancelled',
          refundStatus: 'completed',
          paidAt: _now.subtract(const Duration(hours: 1)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();
        expect(find.text('환불 정보'), findsOneWidget);
        expect(find.text('환불완료'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // CUJ 5-2: 무료 이벤트 취소
  // ===========================================================================
  cujGroup('5-2', '무료 이벤트 취소', () {
    cujCase(
      'happy: paymentAmount=0, paymentId=null → 예매 취소 버튼 활성',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-free'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-free',
          paymentAmount: 0,
          paymentId: null,
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 무료 티켓도 canCancel=true (Fix #1652)
        final cancelBtn = t.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '예매 취소'),
        );
        expect(cancelBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'happy: 무료 취소 확인 다이얼로그 → 취소하기 → cancelOrder 호출',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-free'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-free',
          paymentAmount: 0,
          paymentId: null,
        );
        when(
          () => mockRepo.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) async => const CancelOrderResult(type: 'cancelled'));
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // Fix #2589 dev-blocker: 예매 취소 버튼 off-screen → ensureVisible 후 탭.
        await t.ensureVisible(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pump();
        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        // 무료 이벤트: 0원 환불 다이얼로그 (FR-14: PortOne 없이 상태만 변경)
        expect(find.textContaining('원이 환불됩니다'), findsOneWidget);

        final messenger = ScaffoldMessenger.maybeOf(
          t.element(find.byType(PurchaseHistoryDetailPage)),
        );

        await t.tap(find.text('취소하기'));
        await t.pumpAndSettle();

        verify(
          () => mockRepo.cancelOrder(
            eventId: 'event-1',
            reason: any(named: 'reason'),
          ),
        ).called(1);

        // Fix #2589 dev-blocker: SnackBar 3 초 자동 dismiss Timer drain
        // (1-1 happy 동일 패턴 참고).
        messenger?.clearSnackBars();
        await t.pumpAndSettle();
      },
    );

    cujCase(
      'edge: 무료 이벤트 + 이미 취소됨 → 버튼 비활성',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-free-cancelled'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-free-cancelled',
          status: 'cancelled',
          paymentAmount: 0,
          paymentId: null,
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // status='cancelled' → canCancel=false (FR-1: 재취소 차단)
        final cancelBtn = t.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '예매 취소'),
        );
        expect(cancelBtn.onPressed, isNull);
      },
    );
  });
}
