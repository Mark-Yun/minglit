// CUJ tests — event / refund-policy-v2
//
// 대응 spec: docs/features/event/refund-policy-v2/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위:
//   - CUJ 1-1: grace period(3시간) 내 자동 환불 (P0)
//   - CUJ 1-2: grace period 내 다이얼로그에서 돌아가기 (P0)
//   - CUJ 1-3: 환불 완료 후 라벨 표시 (P1)
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

import 'package:app_user/src/features/payment/logic/'
    'purchase_history_detail_controller.dart';
import 'package:app_user/src/features/payment/ui/'
    'purchase_history_detail_page.dart';
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

class _MockUser extends Mock implements User {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _now = DateTime.now();

Event _makeEvent({
  String id = 'event-1',
  String status = 'scheduled',
  DateTime? startTime,
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
    event: _makeEvent(startTime: eventStartTime),
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

  setUp(() {
    mockRepo = _MockEventRepository();
    mockUser = _MockUser();
    when(() => mockUser.id).thenReturn('user-1');
    when(
      () => mockRepo.getMyPurchaseHistory(any()),
    ).thenAnswer((_) async => []);
  });

  // base overrides: controller notifier 생성에 필요한 최소 세트.
  List<dynamic> base() => [
    currentUserProvider.overrideWith((_) => mockUser),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    eventRepositoryProvider.overrideWithValue(mockRepo),
  ];

  // Returns overrides for PurchaseHistoryDetailPage rendering with the
  // given application.
  List<dynamic> withApp(EventApplication app) => [
    purchaseHistoryDetailProvider(app.id).overrideWith((_) async => app),
    ...base(),
  ];

  // ===========================================================================
  // CUJ 1-1: grace period(3시간) 내 자동 환불
  // ===========================================================================
  cujGroup('1-1', 'grace period(3시간) 내 자동 환불', () {
    cujCase(
      'happy: 결제 30분 후 취소 → 예매 취소 버튼 활성',
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
          (_) async => const CancelOrderResult(
            type: 'refunded',
            refundAmount: 50000,
          ),
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

        // "취소하기" 탭 → cancelOrder 호출
        await t.tap(find.text('취소하기'));
        await t.pumpAndSettle();

        verify(
          () => mockRepo.cancelOrder(
            eventId: 'event-1',
            reason: any(named: 'reason'),
          ),
        ).called(1);
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
        expect(
          find.widgetWithText(ElevatedButton, '예매 취소'),
          findsNothing,
        );

        // 환불 정보 섹션 노출 (isRefunded=true)
        expect(find.text('환불 정보'), findsOneWidget);
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
        ).thenAnswer(
          (_) async => const CancelOrderResult(type: 'cancelled'),
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

        // 무료 이벤트: 0원 환불 다이얼로그 (FR-14: PortOne 없이 상태만 변경)
        expect(find.textContaining('원이 환불됩니다'), findsOneWidget);

        await t.tap(find.text('취소하기'));
        await t.pumpAndSettle();

        verify(
          () => mockRepo.cancelOrder(
            eventId: 'event-1',
            reason: any(named: 'reason'),
          ),
        ).called(1);
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
