import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settlement_coordinator.g.dart';

@riverpod
class SettlementCoordinator extends _$SettlementCoordinator {
  @override
  void build() {}

  void goToSettlement() {
    ref.read(goRouterProvider).go(const SettlementRoute().location);
  }

  void goToDetail(String itemId) {
    unawaited(
      ref
          .read(goRouterProvider)
          .push(SettlementDetailRoute(id: itemId).location),
    );
  }

  void goToBankAccount() {
    unawaited(
      ref.read(goRouterProvider).push(const BankAccountRoute().location),
    );
  }

  Future<void> retryPayout(
    BuildContext context, {
    required String payoutId,
    required String partnerId,
  }) async {
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      await ref
          .read(settlementRepositoryProvider)
          .retryPayout(payoutId: payoutId, partnerId: partnerId);
      if (context.mounted) {
        context.showMinglitSuccess('재지급 요청이 완료되었습니다.');
      }
    } on Object catch (e, st) {
      if (context.mounted) {
        handleMinglitError(context, e, st);
      }
    } finally {
      loading.hide();
    }
  }
}
