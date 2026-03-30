import 'dart:async';

import 'package:app_partner/src/features/settlement/settlement_models.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settlement_controller.freezed.dart';
part 'settlement_controller.g.dart';

@freezed
abstract class SettlementState with _$SettlementState {
  const factory SettlementState({
    @Default(PartnerRevenueSummary()) PartnerRevenueSummary revenueSummary,
    @Default([]) List<PartnerMonthlyRevenue> monthlyRevenue,
    @Default([]) List<PartnerSettlement> settlements,
    @Default(AsyncValue<void>.loading()) AsyncValue<void> status,
  }) = _SettlementState;
}

@riverpod
class SettlementController extends _$SettlementController {
  @override
  SettlementState build() {
    unawaited(Future.microtask(loadSettlementData));
    return const SettlementState();
  }

  Future<void> loadSettlementData() async {
    state = state.copyWith(status: const AsyncValue.loading());

    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) {
        state = state.copyWith(status: const AsyncValue.data(null));
        return;
      }

      final partnerRepo = ref.read(partnerRepositoryProvider);

      final revenueJson = await partnerRepo.getPartnerRevenueStats(
        partner.id,
      );
      final revenueSummary = PartnerRevenueSummary.fromJson(revenueJson);

      final monthlyJson = await partnerRepo.getPartnerMonthlyRevenue(
        partner.id,
      );
      final monthlyRevenue = monthlyJson
          .map(PartnerMonthlyRevenue.fromJson)
          .toList(growable: false);

      final settlementJson = await partnerRepo.getPartnerSettlements(
        partner.id,
      );
      final settlements = settlementJson
          .map(PartnerSettlement.fromJson)
          .toList(growable: false);

      state = state.copyWith(
        status: const AsyncValue.data(null),
        revenueSummary: revenueSummary,
        monthlyRevenue: monthlyRevenue,
        settlements: settlements,
      );
    } on Exception catch (e, st) {
      state = state.copyWith(status: AsyncValue.error(e, st));
    }
  }
}
