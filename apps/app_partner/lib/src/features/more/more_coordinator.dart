import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final moreCoordinatorProvider = Provider<MoreCoordinator>((ref) {
  return MoreCoordinator(ref.read(goRouterProvider));
});

class MoreCoordinator {
  MoreCoordinator(this._router);

  final GoRouter _router;

  void pushNotificationSettings() {
    unawaited(_router.push(const NotificationSettingsRoute().location));
  }

  void pushMemberList(String partnerId) {
    unawaited(_router.push(MemberListRoute(partnerId: partnerId).location));
  }

  void pushVerificationManage() {
    unawaited(_router.push(const VerificationManageRoute().location));
  }

  // Fix #1269: 더보기에서 파티 관리 메뉴가 누락되어 파티 목록으로 진입할 수 없었다.
  void pushPartyList() {
    unawaited(_router.push(const PartyListRoute().location));
  }

  // Fix #1568: 정산 계좌 관리 진입점
  // Fix #1834: push() cross-branch (/more → /settlement) fails silently in
  // StatefulShellRoute (same class of bug as #1680). Use go() to switch branch
  // directly — matching the pattern of goToSettlement() in SettlementCoordinator.
  void pushBankAccountManagement() {
    _router.go(const BankAccountRoute().location);
  }

  void pushAccountDeletion() {
    unawaited(_router.push(const DeletionReasonRoute().location));
  }

  // Fix #1213: 계정 관리 서브페이지 진입점
  void pushAccountManagement() {
    unawaited(_router.push(const PartnerAccountManagementRoute().location));
  }

  // Fix #404: Coordinator-based navigation for home route (logout)
  void goToHome() {
    _router.go('/');
  }
}
