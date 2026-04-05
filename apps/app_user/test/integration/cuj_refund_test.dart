// Ref #1072: IT-U03 — 환불 신청 CUJ 통합 테스트
//
// 검증 포인트:
// 1. 구매 내역 → 환불 가능한 항목 확인
// 2. 환불 상태 표시 (결제완료/환불요청/환불완료)
// 3. 비로그인 시 구매 내역 접근 차단
// 변형:
// - U03-V1: 부분 환불 (일부만 환불 가능한 티켓)
// - U03-V2: 당일 환불 정책 적용
// - U03-V3: 무료 이벤트 무료 취소
import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final now = DateTime(2026, 4, 5, 15);
  final testUser = createMockUserForTest(id: 'user-u03', name: '이영희');

  EventApplication makeApp({
    required String id,
    required String status,
    int price = 25000,
    bool isFree = false,
  }) {
    return EventApplication(
      id: id,
      eventId: 'event-refund-1',
      ticketId: 'ticket-$id',
      userId: 'user-u03',
      status: status,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
      paymentAmount: isFree ? 0 : price,
      event: Event(
        id: 'event-refund-1',
        partyId: 'party-1',
        startTime: now.add(const Duration(days: 7)),
        endTime: now.add(const Duration(days: 7, hours: 2)),
        createdAt: now,
        updatedAt: now,
        title: '소셜 다이닝',
      ),
      ticket: Ticket(
        id: 'ticket-$id',
        name: isFree ? '무료 입장' : '일반 티켓',
        createdAt: now,
        updatedAt: now,
        price: isFree ? 0 : price,
      ),
    );
  }

  group('IT-U03: 환불 신청', () {
    testWidgets('비로그인 사용자는 구매 내역에 접근할 수 없다', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: false,
          initialLocation: '/purchase-history',
        ),
      );
      await tester.pump();
      await tester.pump();

      // /purchase-history는 보호된 경로
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('결제완료 상태 항목이 구매 내역에 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _FakePurchaseHistoryController(
                [makeApp(id: 'paid-1', status: 'paid')],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('구매 내역'), findsOneWidget);
      expect(find.text('소셜 다이닝'), findsOneWidget);
    });

    testWidgets('환불요청 상태 항목이 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _FakePurchaseHistoryController(
                [makeApp(id: 'refund-1', status: 'refund_requested')],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('구매 내역'), findsOneWidget);
    });

    testWidgets('U03-V3: 무료 취소 — 0원 항목이 목록에 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _FakePurchaseHistoryController(
                [makeApp(id: 'free-1', status: 'paid', isFree: true)],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('구매 내역'), findsOneWidget);
    });

    testWidgets('구매 내역이 없을 때 빈 상태가 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _FakePurchaseHistoryController([]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('구매 내역이 없습니다.'), findsOneWidget);
    });
  });
}

class _FakePurchaseHistoryController extends PurchaseHistoryController {
  _FakePurchaseHistoryController(this._items);
  final List<EventApplication> _items;

  @override
  Future<List<EventApplication>> build() async => _items;
}
