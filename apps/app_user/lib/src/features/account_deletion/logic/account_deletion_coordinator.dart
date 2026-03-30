import 'dart:async';

import 'package:app_user/src/features/account_deletion/account_deletion_flow.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_deletion_coordinator.g.dart';

@riverpod
AccountDeletionCoordinator accountDeletionCoordinator(Ref ref) {
  return AccountDeletionCoordinator(ref.read(goRouterProvider));
}

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
          reasonText: reason?.detail,
        ).location,
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
          reasonText: reason?.detail,
        ).location,
      ),
    );
  }

  void goComplete() {
    _router.go(const DeletionCompleteRoute().location);
  }
}
