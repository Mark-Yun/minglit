import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final homeCoordinatorProvider = Provider<HomeCoordinator>((ref) {
  return HomeCoordinator(ref.read(goRouterProvider));
});

class HomeCoordinator {
  HomeCoordinator(this._router);

  final GoRouter _router;

  // Fix #634: goToLogin을 home_coordinator로 이동 — auth_coordinator 직접 참조 제거
  void goToLogin({String? from}) {
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
    _router.go('/');
  }

  void pushPrivacy() {
    unawaited(_router.push(const PrivacyRoute().location));
  }

  void pushBlockedPartners() {
    unawaited(_router.push(const BlockedPartnersRoute().location));
  }

  // Fix #852: Navigate to ticket QR via coordinator
  // — removes cross-feature import
  void pushTicketQR(String ticketId) {
    unawaited(_router.push(TicketQRRoute(ticketId: ticketId).location));
  }

  void pushEventDetail(String eventId) {
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
}
