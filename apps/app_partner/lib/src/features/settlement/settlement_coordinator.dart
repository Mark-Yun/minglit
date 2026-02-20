import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settlement_coordinator.g.dart';

@riverpod
class SettlementCoordinator extends _$SettlementCoordinator {
  @override
  void build() {}

  void goToSettlement() {
    ref.read(goRouterProvider).go(const SettlementRoute().location);
  }
}
