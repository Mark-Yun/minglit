import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final partnerCoordinatorProvider = Provider<PartnerCoordinator>((ref) {
  return PartnerCoordinator(ref.read(goRouterProvider));
});

// Fix #634: partner feature 전용 coordinator — home_coordinator 직접 참조 제거
class PartnerCoordinator {
  PartnerCoordinator(this._router);

  final GoRouter _router;

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
