import 'dart:async';

import 'package:app_user/src/routing/app_coordinator.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

final homeCoordinatorProvider = Provider<HomeCoordinator>((ref) {
  return HomeCoordinator(
    ref.read(goRouterProvider),
    ref.read(appCoordinatorProvider),
  );
});

class HomeCoordinator {
  HomeCoordinator(this._router, [this._app]);

  final GoRouter _router;
  final AppCoordinator? _app;

  // Fix #634: goToLogin을 home_coordinator로 이동 — auth_coordinator 직접 참조 제거
  void goToLogin({String? from}) {
    final app = _app;
    if (app != null) {
      app.goToLogin(from: from);
      return;
    }
    _router.go(LoginRoute(from: from).location);
  }

  void pushNotificationCenter() {
    unawaited(_router.push(const NotificationCenterRoute().location));
  }

  void pushPurchaseHistory() {
    unawaited(_router.push(const PurchaseHistoryRoute().location));
  }

  // Fix #641: MyTicketsRoute 네비게이션 — "내 티켓" 탭에서 MyTicketsPage로 이동
  void pushMyTickets() {
    unawaited(_router.push(const MyTicketsRoute().location));
  }

  void goToPurchaseHistory() {
    _router.go(const PurchaseHistoryRoute().location);
  }

  void pushNotificationSettings() {
    unawaited(_router.push(const NotificationSettingsRoute().location));
  }

  // Fix #404: Coordinator-based navigation for home route
  void goToHome() {
    final app = _app;
    if (app != null) {
      app.goToHome();
      return;
    }
    _router.go('/');
  }

  void pushPrivacy() {
    unawaited(_router.push(const PrivacyRoute().location));
  }

  void pushBlockedPartners() {
    unawaited(_router.push(const BlockedPartnersRoute().location));
  }

  // Fix #1630: context.push() in AppBar 콜백은 내부 Navigator context를 사용해
  // 무음 실패(silent failure)가 발생함 — goRouterProvider로 주입된 root GoRouter
  // 인스턴스를 통해 push해야 올바르게 동작함 (PR #1724 패턴과 동일).
  void pushSearch() {
    unawaited(_router.push(const SearchRoute().location));
  }

  // Fix #1630: AppBar context.push() → GoRouter 주입 패턴
  void pushMyPage() {
    unawaited(_router.push(const MyPageRoute().location));
  }

  void pushEventDetail(String eventId) {
    final app = _app;
    if (app != null) {
      app.pushEventDetail(eventId);
      return;
    }
    unawaited(_router.push(EventDetailRoute(eventId: eventId).location));
  }

  void pushPartnerEvents({
    required String partnerId,
    required String partnerName,
  }) {
    unawaited(
      _router.push(
        PartnerEventsRoute(
          partnerId: partnerId,
          partnerName: partnerName,
        ).location,
      ),
    );
  }

  // Fix #1213: 계정 관리 서브페이지 진입점
  void pushAccountManagement() {
    unawaited(_router.push(const AccountManagementRoute().location));
  }

  // Fix #1526: HomeCoordinator public API 유지 — 테스트/화면 호출부는 그대로 두고
  // 내부 네비게이션만 AppCoordinator로 위임해 cross-feature import 제거.
  void pushTicketQR(String ticketId, {TicketEventMeta? eventMeta}) {
    final app = _app;
    if (app != null) {
      app.pushTicketQR(ticketId, eventMeta: eventMeta);
      return;
    }
    unawaited(
      _router.push(
        TicketQRRoute(ticketId: ticketId).location,
        extra: eventMeta,
      ),
    );
  }

  // AppPermissionSettingsScreen은 GoRouter 라우트가 없어 Navigator.push 사용.
  // 위젯에서 직접 MaterialPageRoute를 생성하지 않도록 Coordinator로 위임.
  void navigateToPermissionSettings(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AppPermissionSettingsScreen()),
    );
  }
}
