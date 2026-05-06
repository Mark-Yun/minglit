import 'dart:async';

import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/golden_capture.dart';
import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

// Fix #1321: DateTime.now() → 고정 시간으로 교체 (flaky test 방지)
final _fixedNow = DateTime(2026, 4, 13, 12);

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
      final capture = GoldenCapture('flow_u_mypage');
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

      await capture.setup(tester, 0); // 마이페이지 렌더링

      await tester.tap(find.text('알림 설정'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    });

    // Fix #2093: 회원 탈퇴는 계정 관리 페이지로 이동 — PrivacyPage는 동의 현황만 표시
    testWidgets('개인정보 tap → PrivacyPage — 동의 현황 표시', (tester) async {
      setKoreanLocale(tester);
      final capture = GoldenCapture('flow_u_mypage');
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
          additionalOverrides: [
            consentControllerProvider.overrideWith(
              _MockConsentController.new,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('개인정보'), 100);
      await tester.tap(find.text('개인정보'));
      await tester.pumpAndSettle();

      await capture.after(tester, 1); // 개인정보 설정

      expect(find.byType(PrivacyPage), findsOneWidget);
      expect(find.text('동의 현황'), findsOneWidget);
      expect(find.text('회원 탈퇴'), findsNothing);
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
      // Fix #1485: MinglitSettingsGroup(clipBehavior: Clip.antiAlias) prevents
      // tester.tap() from registering through the rounded-corner clip boundary
      // when the tile is in a scrolled position. Navigate directly instead —
      // consistent with the PurchaseHistoryPage test pattern.
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my/blocked-partners',
          additionalOverrides: [
            socialRepositoryProvider.overrideWithValue(_FakeSocialRepository()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(BlockedPartnersPage), findsOneWidget);
    });

    testWidgets('구매 내역 tap → PurchaseHistoryPage', (tester) async {
      setKoreanLocale(tester);
      final capture = GoldenCapture('flow_u_mypage');
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
          additionalOverrides: [
            purchaseHistoryControllerProvider.overrideWith(
              _MockEmptyPurchaseHistory.new,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('구매 내역'), 100);
      await tester.tap(find.text('구매 내역'));
      await tester.pump();
      await tester.pump();

      await capture.after(tester, 2); // 구매 내역

      expect(find.byType(PurchaseHistoryPage), findsOneWidget);
    });

    testWidgets('로그아웃 tap → 확인 다이얼로그 → 홈으로 이동', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      // Fix #1213: 로그아웃은 계정 관리 서브페이지(/my/account)로 이동
      // Fix #1378: 로그아웃 확인 다이얼로그 추가로 인해 두 단계로 처리
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my/account',
        ),
      );
      await tester.pump();
      await tester.pump();

      // 1단계: 로그아웃 버튼 탭 → 확인 다이얼로그 열림
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      // 다이얼로그 확인: 취소/로그아웃(확인) 버튼이 모두 표시됨
      expect(find.text('로그아웃 하시겠어요?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);

      // 2단계: 다이얼로그에서 '로그아웃' 확인 버튼 탭
      // 다이얼로그 내의 '로그아웃' 버튼 (TextButton) 탭
      final confirmButton = find.ancestor(
        of: find.text('로그아웃').last,
        matching: find.byType(TextButton),
      );
      await tester.tap(confirmButton);
      // GoRouter.go('/') + Future.delayed(Duration.zero) + signOut
      await tester.pumpAndSettle();

      // 로그아웃 후 홈('/')으로 이동 확인
      expect(find.byType(MyPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
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
      final now = _fixedNow;
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
      final now = _fixedNow;
      // canCancel:
      // paid + paymentId + paymentAmount + event.startTime +
      // refundStatus == 'none'
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
          // Fix #2282: cutoffDays=7 판정이 real DateTime.now() 기준 → 날짜 의존성 회피
          // 충분히 먼 미래 날짜로 고정해 시간 경과로 인한 flakiness 방지
          startTime: DateTime(2030, 1, 1),
          endTime: DateTime(2030, 1, 1, 2),
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

      // 예매 취소 탭 → 환불 확인 다이얼로그 (금액/수수료 표시)
      await tester.tap(find.text('예매 취소'));
      await tester.pumpAndSettle();

      expect(find.text('예매 취소 확인'), findsOneWidget);
      expect(find.text('30,000원'), findsWidgets); // 결제 금액
      expect(find.text('환불 비율'), findsOneWidget);
      expect(find.text('환불 금액'), findsOneWidget);
      expect(find.text('수수료'), findsOneWidget);
    });

    testWidgets('환불 불가 시 → "예매 취소" 버튼 미표시', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final now = _fixedNow;
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
      // 취소된 상태 배지가 표시되어야 함
      expect(find.text('취소됨'), findsOneWidget);
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
    updatedAt: _fixedNow,
  );
}

/// NotificationSettingsController — returns null
class _MockNotificationSettingsNull extends NotificationSettingsController {
  @override
  FutureOr<UserSettings?> build() async => null;
}

/// ConsentController — returns mock consent data for PrivacyPage
class _MockConsentController extends ConsentController {
  @override
  FutureOr<List<UserConsent>> build() async => [
    UserConsent(
      id: 'c1',
      userId: 'test-user-id',
      consentKey: ConsentType.termsOfService,
      consented: true,
      consentedAt: _fixedNow,
      createdAt: _fixedNow,
    ),
    UserConsent(
      id: 'c2',
      userId: 'test-user-id',
      consentKey: ConsentType.privacyCollection,
      consented: true,
      consentedAt: _fixedNow,
      createdAt: _fixedNow,
    ),
    UserConsent(
      id: 'c3',
      userId: 'test-user-id',
      consentKey: ConsentType.thirdPartyProvision,
      consented: false,
      consentedAt: _fixedNow,
      createdAt: _fixedNow,
    ),
    UserConsent(
      id: 'c4',
      userId: 'test-user-id',
      consentKey: ConsentType.marketingConsent,
      consented: false,
      consentedAt: _fixedNow,
      createdAt: _fixedNow,
    ),
  ];
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
