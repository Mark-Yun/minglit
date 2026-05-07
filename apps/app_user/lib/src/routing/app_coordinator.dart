import 'dart:async';

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/logic/ticket_event_meta.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

final appCoordinatorProvider = Provider<AppCoordinator>((ref) {
  return AppCoordinator(
    ref.read(goRouterProvider),
    ref.read(accountDeletionCoordinatorProvider),
  );
});

/// Shared navigation coordinator for cross-feature navigation.
///
/// Lives in the routing layer so any feature can import it without
/// creating feature-to-feature dependencies.
class AppCoordinator {
  AppCoordinator(this._router, this._accountDeletion);

  final GoRouter _router;
  final AccountDeletionCoordinator _accountDeletion;

  void goToHome() {
    _router.go('/');
  }

  // Fix #634: goToLogin — shared entry point for login navigation
  void goToLogin({String? from}) {
    _router.go(LoginRoute(from: from).location);
  }

  void pushEventDetail(String eventId) {
    unawaited(_router.push(EventDetailRoute(eventId: eventId).location));
  }

  void pushEventMatching(String eventId) {
    unawaited(_router.push(EventMatchingRoute(eventId: eventId).location));
  }

  // Fix #1526: eventMeta for boarding pass display
  void pushTicketQR(String ticketId, {TicketEventMeta? eventMeta}) {
    unawaited(
      _router.push(
        TicketQRRoute(ticketId: ticketId).location,
        extra: eventMeta,
      ),
    );
  }

  void pushPurchaseHistory() {
    unawaited(_router.push(const PurchaseHistoryRoute().location));
  }

  void startAccountDeletion() {
    _accountDeletion.start();
  }
}
