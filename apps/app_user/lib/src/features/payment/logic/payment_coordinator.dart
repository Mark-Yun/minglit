import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_coordinator.g.dart';

@riverpod
PaymentCoordinator paymentCoordinator(Ref ref) {
  return PaymentCoordinator(ref.read(goRouterProvider));
}

class PaymentCoordinator {
  PaymentCoordinator(this._router);

  final GoRouter _router;

  void pushPurchaseHistory() {
    unawaited(_router.push(const PurchaseHistoryRoute().location));
  }

  void goToPurchaseHistory() {
    _router.go(const PurchaseHistoryRoute().location);
  }
}
