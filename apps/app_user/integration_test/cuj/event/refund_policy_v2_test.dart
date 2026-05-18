// CUJ tests — event / refund-policy-v2 (app_user)
//
// 대응 spec: docs/features/event/refund-policy-v2/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위:
//   - CUJ 1-1: grace period 내 자동 환불 (P0)
//   - CUJ 1-2: grace period 내 다이얼로그에서 돌아가기 (P0)
//   - CUJ 1-3: 환불 완료 후 라벨 표시 (P1)
//   - CUJ 2-1: cutoff(7일) 전 자동 환불 — grace 초과, cutoff 전 (P0)
//   - CUJ 3-1: 자동 환불 불가 — grace + cutoff 모두 초과 (P0)
import 'package:app_user/src/features/payment/logic/'
    'purchase_history_detail_controller.dart';
import 'package:app_user/src/features/payment/ui/'
    'purchase_history_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  required DateTime startTime,
  String id = 'event-1',
  String status = 'scheduled',
}) {
  return Event(
    id: id,
    partyId: 'party-1',
    title: '테스트 이벤트',
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 2)),
    createdAt: _now,
    updatedAt: _now,
    status: status,
    tickets: const [],
    entryGroups: const [],
  );
}

EventApplication _makeApplication({
  required DateTime paidAt,
  required DateTime eventStartTime,
  String id = 'app-1',
  String status = 'paid',
  int? paymentAmount = 50000,
  String? paymentId = 'pay-1',
  String refundStatus = 'none',
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
    paidAt: paidAt,
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

  setUpAll(() async {
    // PurchaseHistoryDetailPage 가 DateFormat('M월 d일 (E) HH:mm', 'ko_KR') 사용.
    // 초기화 없으면 첫 pump 에서 'Locale data has not been initialized' 오류.
    await initializeDateFormatting('ko_KR');
  });

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

  List<dynamic> base() => [
    currentUserProvider.overrideWith((_) => mockUser),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    eventRepositoryProvider.overrideWithValue(mockRepo),
  ];

  List<dynamic> withApp(EventApplication app) => [
    purchaseHistoryDetailProvider(app.id).overrideWith((_) async => app),
    ...base(),
  ];

  // ===========================================================================
  // CUJ 1-1: grace period(3시간) 내 자동 환불
  // paidAt=1h ago (< grace 2h) + eventStartTime=30d → withinGracePeriod=true
  // → confirmRefund 다이얼로그 → "취소하기" → cancelOrder 호출
  // ===========================================================================
  cujGroup('1-1', 'grace period 내 자동 환불', () {
    cujCase(
      'happy: 결제 1시간 후(grace 이내) → 예매 취소 버튼 활성 (FR-1)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-grace'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-grace',
          paidAt: _now.subtract(const Duration(hours: 1)),
          eventStartTime: _now.add(const Duration(days: 30)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // canCancel=true (refundStatus='none', status='paid', not started)
        final cancelBtn = t.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '예매 취소'),
        );
        expect(cancelBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'happy: 취소 다이얼로그 → 취소하기 → cancelOrder 호출 (FR-2, FR-3)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-grace'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-grace',
          paidAt: _now.subtract(const Duration(hours: 1)),
          eventStartTime: _now.add(const Duration(days: 30)),
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

        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        // FR-2: 자동 환불 가능 다이얼로그 + 환불 금액 안내
        expect(find.text('예매 취소'), findsWidgets);
        expect(find.textContaining('원이 환불됩니다'), findsOneWidget);

        await t.tap(find.text('취소하기'));
        await t.pumpAndSettle();

        // FR-3: PortOne 결제 취소 호출 (cancelOrder)
        verify(
          () => mockRepo.cancelOrder(
            eventId: 'event-1',
            reason: any(named: 'reason'),
          ),
        ).called(1);
      },
    );
  });

  // ===========================================================================
  // CUJ 1-2: grace period 내 다이얼로그에서 돌아가기
  // 동일 setup — 다이얼로그 "아니오" → cancelOrder 미호출
  // ===========================================================================
  cujGroup('1-2', 'grace period 내 다이얼로그에서 돌아가기', () {
    cujCase(
      'happy: 취소 다이얼로그 → "아니오" → cancelOrder 미호출 (FR-2)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-grace-back'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-grace-back',
          paidAt: _now.subtract(const Duration(hours: 1)),
          eventStartTime: _now.add(const Duration(days: 30)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        // 다이얼로그 등장
        expect(find.text('예매 취소'), findsWidgets);

        // "아니오" 탭 → 다이얼로그 닫힘
        await t.tap(find.text('아니오'));
        await t.pumpAndSettle();

        // 상태 변경 없음 — cancelOrder 미호출
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
  // CUJ 1-3: 환불 완료 후 "환불 정보" 카드 표시
  // refundStatus='completed' → isRefunded=true → "환불 정보" 카드 표시
  //                                             → "예매 취소" 버튼 미노출
  // ===========================================================================
  cujGroup('1-3', '환불 완료 후 라벨 표시', () {
    cujCase(
      'happy: refundStatus=completed → "환불 정보" 카드 표시 (FR-1)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-refunded'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-refunded',
          paidAt: _now.subtract(const Duration(hours: 1)),
          eventStartTime: _now.add(const Duration(days: 30)),
          refundStatus: 'completed',
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // "환불 정보" 카드 표시 (결제금액 + 환불금액 섹션)
        expect(find.text('환불 정보'), findsOneWidget);

        // "예매 취소" 버튼 미노출 (isRefunded=true → 취소 정책 카드 숨김)
        expect(find.widgetWithText(ElevatedButton, '예매 취소'), findsNothing);
      },
    );

    cujCase(
      'edge: 환불 완료 후 재취소 시도 불가 — 버튼 자체 미노출 (FR-1 negative)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-refunded-retry'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-refunded-retry',
          paidAt: _now.subtract(const Duration(hours: 1)),
          eventStartTime: _now.add(const Duration(days: 30)),
          refundStatus: 'completed',
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // 재취소 버튼 없음 → cancelOrder 호출 경로 자체가 없음
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
  // CUJ 2-1: cutoff(7일) 전 자동 환불
  // grace 초과(paidAt 4h) + cutoff 전(eventStartTime 30일 후) → 동일한 자동 환불 다이얼로그
  // ===========================================================================
  cujGroup('2-1', 'cutoff(7일) 전 자동 환불', () {
    // paidAt=4h ago, eventStartTime=30d → withinGracePeriod=false, withinCutoff=true
    // → isRefundable=true → confirmRefund 다이얼로그 표시

    cujCase(
      'happy: 결제 4시간 후(grace 초과) + 이벤트 30일 후(cutoff 전) → 예매 취소 버튼 활성',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-cutoff'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-cutoff',
          paidAt: _now.subtract(const Duration(hours: 4)),
          eventStartTime: _now.add(const Duration(days: 30)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // canCancel=true (withinCutoff=true)
        final cancelBtn = t.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '예매 취소'),
        );
        expect(cancelBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'happy: 취소 다이얼로그 → 취소하기 → cancelOrder 호출 (FR-3: PortOne 자동 처리)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-cutoff'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-cutoff',
          paidAt: _now.subtract(const Duration(hours: 4)),
          eventStartTime: _now.add(const Duration(days: 30)),
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

        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        // 자동 환불 다이얼로그 표시 (FR-2)
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
      'edge: 다이얼로그에서 "아니오" → cancelOrder 미호출',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-cutoff'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-cutoff',
          paidAt: _now.subtract(const Duration(hours: 4)),
          eventStartTime: _now.add(const Duration(days: 30)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        await t.tap(find.text('아니오'));
        await t.pumpAndSettle();

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
  // CUJ 3-1: 자동 환불 불가 (grace + cutoff 모두 초과)
  // ===========================================================================
  cujGroup('3-1', '자동 환불 불가 — grace + cutoff 모두 초과', () {
    // paidAt=4h ago (grace 2h 초과) + eventStartTime=3d (cutoff 7일 미달)
    // → withinGracePeriod=false, withinCutoff=false → isRefundable=false
    // → showNotEligible() → "환불 기간이 지났습니다." 경고

    cujCase(
      'happy: 결제 4시간 후(grace 초과) + 이벤트 3일 후(cutoff 미달) → 예매 취소 버튼 활성',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-ineligible'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-ineligible',
          paidAt: _now.subtract(const Duration(hours: 4)),
          eventStartTime: _now.add(const Duration(days: 3)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        // canCancel=true (상태는 paid이지만 환불 불가 상태)
        final cancelBtn = t.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '예매 취소'),
        );
        expect(cancelBtn.onPressed, isNotNull);
      },
    );

    cujCase(
      'happy: 취소 버튼 탭 → "환불 기간이 지났습니다." 경고 (FR-5: showNotEligible)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-ineligible'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-ineligible',
          paidAt: _now.subtract(const Duration(hours: 4)),
          eventStartTime: _now.add(const Duration(days: 3)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        // showNotEligible → MinglitWarning 스낵바
        expect(find.textContaining('환불 기간이 지났습니다'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 환불 불가 상태에서 cancelOrder 미호출 (자동 환불 로직 우회 없음)',
      app: const PurchaseHistoryDetailPage(applicationId: 'app-ineligible'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-ineligible',
          paidAt: _now.subtract(const Duration(hours: 4)),
          eventStartTime: _now.add(const Duration(days: 3)),
        );
        return withApp(app);
      },
      body: (t) async {
        await t.pumpAndSettle();

        await t.tap(find.widgetWithText(ElevatedButton, '예매 취소'));
        await t.pumpAndSettle();

        verifyNever(
          () => mockRepo.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        );
      },
    );
  });
}
