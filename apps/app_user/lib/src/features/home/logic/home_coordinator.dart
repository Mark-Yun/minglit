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
  HomeCoordinator(this._router, this._app);

  final GoRouter _router;
  final AppCoordinator _app;

  // Fix #634: goToLogin을 home_coordinator로 이동 — auth_coordinator 직접 참조 제거
  void goToLogin({String? from}) => _app.goToLogin(from: from);

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
  void goToHome() => _app.goToHome();

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

  void pushEventDetail(String eventId) => _app.pushEventDetail(eventId);

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

  // AppPermissionSettingsScreen은 GoRouter 라우트가 없어 Navigator.push 사용.
  // 위젯에서 직접 MaterialPageRoute를 생성하지 않도록 Coordinator로 위임.
  void navigateToPermissionSettings(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AppPermissionSettingsScreen()),
    );
  }
}
