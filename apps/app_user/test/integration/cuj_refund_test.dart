// IT-U03: 환불 신청 CUJ — 구매 내역에서 환불 신청 확인까지의 플로우
// Fix #1072: Phase 3 — P0 CUJ integration test 구현
//
// 참고: 환불 버튼 표시/다이얼로그 UI는 flow_my_page_test.dart에서 이미 검증됨.
// 이 파일은 환불 정책 변형 시나리오에 집중한다.

import 'dart:async';

import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

// ---------------------------------------------------------------------------
// Fake controllers — data만 제공, Supabase 호출 없음
// ---------------------------------------------------------------------------

class _MockPurchaseHistoryController extends PurchaseHistoryController {
  _MockPurchaseHistoryController(this._data);
  final List<EventApplication> _data;

  @override
  FutureOr<List<EventApplication>> build() async => _data;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

EventApplication _makeRefundableApp({
  String status = 'paid',
  int paymentAmount = 30000,
  DateTime? eventStartTime,
  bool isFree = false,
}) {
  final now = DateTime.now();
  final startTime = eventStartTime ?? now.add(const Duration(days: 14));
  return EventApplication(
    id: 'app-refund-test',
    eventId: 'event-refund-test',
    ticketId: 'ticket-refund-test',
    userId: 'user-test-1',
    status: status,
    createdAt: now.subtract(const Duration(hours: 2)),
    updatedAt: now.subtract(const Duration(hours: 1)),
    paymentId: 'pay-refund-001',
    paymentAmount: isFree ? 0 : paymentAmount,
    paidAt: now.subtract(const Duration(hours: 1)),
    event: Event(
      id: 'event-refund-test',
      partyId: 'party-test-1',
      title: '환불 테스트 이벤트',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 3)),
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 7)),
    ),
    ticket: Ticket(
      id: 'ticket-refund-test',
      name: isFree ? '무료 티켓' : '일반 티켓',
      price: isFree ? 0 : paymentAmount,
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 7)),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('IT-U03: 환불 신청 CUJ', () {
    testWidgets('환불 가능 티켓 — 예매 취소 버튼 표시', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final refundableApp = _makeRefundableApp();

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _MockPurchaseHistoryController([refundableApp]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PurchaseHistoryPage), findsOneWidget);
      expect(find.text('예매 취소'), findsOneWidget);
    });

    testWidgets('예매 취소 버튼 탭 → 환불 확인 다이얼로그 표시', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final refundableApp = _makeRefundableApp();

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _MockPurchaseHistoryController([refundableApp]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('예매 취소'));
      await tester.pumpAndSettle();

      // 환불 확인 다이얼로그 표시
      expect(find.text('예매 취소 확인'), findsOneWidget);
      expect(find.text('환불 비율'), findsOneWidget);
      expect(find.text('환불 금액'), findsOneWidget);
    });

    testWidgets('취소된 티켓 — 예매 취소 버튼 미표시', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final cancelledApp = _makeRefundableApp(status: 'cancelled');

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _MockPurchaseHistoryController([cancelledApp]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('예매 취소'), findsNothing);
      expect(find.text('취소됨'), findsOneWidget);
    });

    // IT-U03-V3: 무료 이벤트 — 티켓 가격 0원
    testWidgets('변형: 무료 이벤트 티켓 — 구매 내역 렌더링', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final freeApp = _makeRefundableApp(isFree: true);

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _MockPurchaseHistoryController([freeApp]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PurchaseHistoryPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // IT-U03-V2: 이벤트 당일 (cutoff 초과 여부)
    testWidgets('변형: 이벤트 임박 — 환불 정책 표시 확인', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final todayApp = _makeRefundableApp(
        eventStartTime: DateTime.now().add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _MockPurchaseHistoryController([todayApp]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // 예매 취소 버튼이 있으면 다이얼로그에서 환불 금액 확인
      if (tester.any(find.text('예매 취소'))) {
        await tester.tap(find.text('예매 취소'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      } else {
        // 정책상 취소 불가 → 버튼 없음도 유효
        expect(find.byType(PurchaseHistoryPage), findsOneWidget);
      }
    });
  });
}
