import 'dart:async';

import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:app_user/src/features/settings/privacy_page.dart';
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

  // ────────────────────────────────────────────────────────────────────────
  // MyPage 메뉴 탭 네비게이션
  // ────────────────────────────────────────────────────────────────────────
  group('MyPage 메뉴 탭', () {
    testWidgets('알림 설정 tap → NotificationSettingsScreen', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
          additionalOverrides: [
            notificationSettingsControllerProvider.overrideWith(
              _MockNotificationSettingsWithData.new,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('알림 설정'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    });

    testWidgets('개인정보 tap → PrivacyPage (Navigator.push)', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('개인정보'), 100);
      await tester.tap(find.text('개인정보'));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPage), findsOneWidget);
      expect(find.text('준비 중입니다'), findsOneWidget);
    });

    testWidgets('권한 설정 tap → AppPermissionSettingsScreen (Navigator.push)', (
      tester,
    ) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('권한 설정'), 100);
      await tester.tap(find.text('권한 설정'));
      // pump() instead of pumpAndSettle() — Geolocator/Firebase platform
      // channels are unavailable in unit tests, so settle never completes.
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppPermissionSettingsScreen), findsOneWidget);
    });

    testWidgets('차단 목록 tap → BlockedPartnersPage (Navigator.push)', (
      tester,
    ) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
          additionalOverrides: [
            socialRepositoryProvider.overrideWithValue(_FakeSocialRepository()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('차단 목록'), 100);
      await tester.tap(find.text('차단 목록'));
      await tester.pumpAndSettle();

      expect(find.byType(BlockedPartnersPage), findsOneWidget);
    });

    testWidgets('로그아웃 tap → 홈으로 이동', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('로그아웃'), 100);
      await tester.tap(find.text('로그아웃'));
      // GoRouter.go('/') + Future.delayed(Duration.zero) + signOut
      await tester.pumpAndSettle();

      // 로그아웃 후 홈('/')으로 이동하므로 MyPage가 사라져야 함
      expect(find.byType(MyPage), findsNothing);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // PurchaseHistoryPage
  // ────────────────────────────────────────────────────────────────────────
  group('PurchaseHistoryPage', () {
    testWidgets('빈 구매 → "구매 내역이 없습니다."', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              _MockEmptyPurchaseHistory.new,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PurchaseHistoryPage), findsOneWidget);
      expect(find.text('구매 내역이 없습니다.'), findsOneWidget);
    });

    testWidgets('구매 목록 → 상태 배지 렌더링 (7종)', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final now = DateTime.now();
      final applications = [
        _createApplication(status: 'pending', createdAt: now),
        _createApplication(status: 'pending_review', createdAt: now),
        _createApplication(status: 'approved', createdAt: now),
        _createApplication(status: 'paid', createdAt: now),
        _createApplication(status: 'rejected', createdAt: now),
        _createApplication(status: 'cancelled', createdAt: now),
        _createApplication(status: 'unknown_status', createdAt: now),
      ];

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _MockPurchaseHistoryWithData(applications),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // 각 상태 배지 텍스트 확인 — 7개 카드가 뷰포트에 다 안 보일 수 있으므로 스크롤
      expect(find.text('결제대기'), findsOneWidget);
      expect(find.text('심사중'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('승인됨'), 200);
      expect(find.text('승인됨'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('결제완료'), 200);
      expect(find.text('결제완료'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('반려됨'), 200);
      expect(find.text('반려됨'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('취소됨'), 200);
      expect(find.text('취소됨'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('알수없음'), 200);
      expect(find.text('알수없음'), findsOneWidget);
    });

    testWidgets('환불 가능 시 → "예매 취소" 버튼 표시', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final now = DateTime.now();
      // canCancel: paid + paymentId + paymentAmount + event.startTime + refundStatus == 'none'
      final refundableApp = _createApplication(
        status: 'paid',
        createdAt: now,
        paymentId: 'pay-123',
        paymentAmount: 30000,
        paidAt: now,
        event: Event(
          id: 'evt-1',
          partyId: 'party-1',
          title: 'Test Event',
          startTime: now.add(const Duration(days: 30)),
          endTime: now.add(const Duration(days: 30, hours: 2)),
          createdAt: now,
          updatedAt: now,
        ),
        ticket: Ticket(
          id: 'tkt-1',
          name: 'General',
          price: 30000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _MockPurchaseHistoryWithData([refundableApp]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('예매 취소'), findsOneWidget);
    });

    testWidgets('환불 불가 시 → "예매 취소" 버튼 미표시', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final now = DateTime.now();
      // cancelled status → isActiveTicket returns false → canCancel false
      final nonRefundableApp = _createApplication(
        status: 'cancelled',
        createdAt: now,
        paymentId: 'pay-456',
        paymentAmount: 20000,
      );

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/purchase-history',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              () => _MockPurchaseHistoryWithData([nonRefundableApp]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('예매 취소'), findsNothing);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // NotificationSettingsScreen
  // ────────────────────────────────────────────────────────────────────────
  group('NotificationSettingsScreen', () {
    testWidgets('정상 → SwitchListTile 2개 (서비스/마케팅)', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my/notification-settings',
          additionalOverrides: [
            notificationSettingsControllerProvider.overrideWith(
              _MockNotificationSettingsWithData.new,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      expect(find.text('서비스 알림'), findsOneWidget);
      expect(find.text('마케팅 정보 수신 동의'), findsOneWidget);
    });

    testWidgets('null 데이터 → "설정 정보를 불러올 수 없습니다."', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my/notification-settings',
          additionalOverrides: [
            notificationSettingsControllerProvider.overrideWith(
              _MockNotificationSettingsNull.new,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('설정 정보를 불러올 수 없습니다.'), findsOneWidget);
    });
  });
}

// ────────────────────────────────────────────────────────────────────────
// Mock Controllers
// ────────────────────────────────────────────────────────────────────────

/// PurchaseHistoryController — empty list
class _MockEmptyPurchaseHistory extends PurchaseHistoryController {
  @override
  FutureOr<List<EventApplication>> build() async => [];
}

/// PurchaseHistoryController — with data
class _MockPurchaseHistoryWithData extends PurchaseHistoryController {
  _MockPurchaseHistoryWithData(this._data);
  final List<EventApplication> _data;

  @override
  FutureOr<List<EventApplication>> build() async => _data;
}

/// NotificationSettingsController — returns valid settings
class _MockNotificationSettingsWithData extends NotificationSettingsController {
  @override
  FutureOr<UserSettings?> build() async => UserSettings(
    userId: 'test-user-id',
    updatedAt: DateTime.now(),
  );
}

/// NotificationSettingsController — returns null
class _MockNotificationSettingsNull extends NotificationSettingsController {
  @override
  FutureOr<UserSettings?> build() async => null;
}

/// Fake SocialRepository for BlockedPartnersPage (returns empty list)
class _FakeSocialRepository implements SocialRepository {
  @override
  Future<List<Map<String, dynamic>>> getBlockedPartners() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ────────────────────────────────────────────────────────────────────────
// Test Data Helpers
// ────────────────────────────────────────────────────────────────────────

int _appCounter = 0;

EventApplication _createApplication({
  required String status,
  required DateTime createdAt,
  String? paymentId,
  int? paymentAmount,
  DateTime? paidAt,
  Event? event,
  Ticket? ticket,
}) {
  _appCounter++;
  return EventApplication(
    id: 'app-$_appCounter',
    eventId: 'evt-$_appCounter',
    ticketId: 'tkt-$_appCounter',
    userId: 'test-user-id',
    status: status,
    createdAt: createdAt,
    updatedAt: createdAt,
    paymentId: paymentId,
    paymentAmount: paymentAmount,
    paidAt: paidAt,
    event: event,
    ticket: ticket,
  );
}
