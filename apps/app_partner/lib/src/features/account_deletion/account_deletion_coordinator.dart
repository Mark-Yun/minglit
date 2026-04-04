import 'dart:async';

import 'package:app_partner/src/features/account_deletion/logic/account_deletion_flow.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

final accountDeletionCoordinatorProvider = Provider<AccountDeletionCoordinator>(
  (ref) {
    return AccountDeletionCoordinator(ref.read(goRouterProvider));
  },
);

class AccountDeletionCoordinator {
  AccountDeletionCoordinator(this._router);

  final GoRouter _router;

  void start() {
    unawaited(_router.push(const DeletionReasonRoute().location));
  }

  void pushInfo({WithdrawalReason? reason}) {
    unawaited(
      _router.push(
        DeletionInfoRoute(
          reasonCode: reason == null
              ? null
              : encodeWithdrawalReasonCode(reason.reasonCode),
        ).location,
        extra: reason?.detail,
      ),
    );
  }

  void pushVerify({WithdrawalReason? reason}) {
    unawaited(
      _router.push(
        DeletionVerifyRoute(
          reasonCode: reason == null
              ? null
              : encodeWithdrawalReasonCode(reason.reasonCode),
        ).location,
        extra: reason?.detail,
      ),
    );
  }

  void goComplete() {
    _router.go(const DeletionCompleteRoute().location);
  }

  void goToApplications() {
    _router.go(const ApplicationListRoute().location);
  }

  void goToSettlement() {
    _router.go(const SettlementRoute().location);
  }

  void goToPartyList() {
    _router.go(const PartyListRoute().location);
  }

  void goToHome() {
    _router.go('/');
  }
}
