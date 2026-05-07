import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final partnerHomeCoordinatorProvider = Provider<PartnerHomeCoordinator>((ref) {
  return PartnerHomeCoordinator(ref.read(goRouterProvider));
});

class PartnerHomeCoordinator {
  PartnerHomeCoordinator(this._router);

  final GoRouter _router;

  void pushNotificationCenter() {
    unawaited(_router.push(const NotificationCenterRoute().location));
  }

  void pushApplicationList() {
    unawaited(_router.push(const ApplicationListRoute().location));
  }

  // Fix #1269: 홈에서 장소 가이드 화면으로 이동하는 진입점을 연결한다.
  void pushLocationGuide() {
    unawaited(_router.push(const LocationGuideRoute().location));
  }

  // Fix #635: settlement 탭 전환을 home coordinator를 통해 위임 (feature 격리)
  void goToSettlement() {
    _router.go(const SettlementRoute().location);
  }

  // Fix #845: ApplicationList/Checkin 탭 전환을 coordinator를 통해 위임
  void goToApplicationList() {
    _router.go(const ApplicationListRoute().location);
  }

  void goToCheckin() {
    _router.go(const CheckinRoute().location);
  }

  void pushEventDetail({
    required String partyId,
    required String eventId,
  }) {
    unawaited(
      _router.push(
        EventDetailRoute(partyId: partyId, eventId: eventId).location,
      ),
    );
  }

  void pushPartyEdit(String partyId) {
    unawaited(_router.push(PartyEditRoute(partyId: partyId).location));
  }

  void pushEventCreate(String partyId) {
    unawaited(_router.push(EventCreateRoute(partyId: partyId).location));
  }

  // Fix #1680: context.push() from HomeBranch fails for MoreBranch routes —
  // use root GoRouter instance to cross shell-branch boundaries correctly.
  void pushPartyCreate() {
    unawaited(_router.push(const PartyCreateRoute().location));
  }
}
