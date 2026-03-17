import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settlement_dashboard_controller.freezed.dart';
part 'settlement_dashboard_controller.g.dart';

@freezed
abstract class SettlementDashboardState with _$SettlementDashboardState {
  const factory SettlementDashboardState({
    required DateTime selectedMonth,
    @Default(AsyncValue<void>.loading()) AsyncValue<void> status,
    Map<String, dynamic>? dashboardData,
  }) = _SettlementDashboardState;
}

@riverpod
class SettlementDashboardController extends _$SettlementDashboardController {
  @override
  SettlementDashboardState build() {
    final now = DateTime.now();
    final initialState = SettlementDashboardState(
      selectedMonth: DateTime(now.year, now.month),
    );
    unawaited(Future.microtask(loadDashboard));
    return initialState;
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(status: const AsyncValue.loading());
    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) {
        state = state.copyWith(status: const AsyncValue.data(null));
        return;
      }
      final repo = ref.read(settlementRepositoryProvider);
      final month = state.selectedMonth;
      final data = await repo.getSettlementDashboard(
        partnerId: partner.id,
        periodStart: month,
        periodEnd: DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999),
      );
      state = state.copyWith(
        status: const AsyncValue.data(null),
        dashboardData: data,
      );
    } on Exception catch (e, st) {
      state = state.copyWith(status: AsyncValue.error(e, st));
    }
  }

  void changeMonth(int delta) {
    final current = state.selectedMonth;
    state = state.copyWith(
      selectedMonth: DateTime(current.year, current.month + delta),
      dashboardData: null,
    );
    unawaited(loadDashboard());
  }
}
