import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_dashboard_controller.freezed.dart';
part 'partner_dashboard_controller.g.dart';

@freezed
abstract class PartnerDashboardState with _$PartnerDashboardState {
  const factory PartnerDashboardState({
    @Default(0) int pendingReviewCount,
    @Default([]) List<Event> todayEvents,
    @Default(false) bool hasRevenuePermission,
    @Default(AsyncValue<void>.loading()) AsyncValue<void> status,
  }) = _PartnerDashboardState;
}

@riverpod
class PartnerDashboardController extends _$PartnerDashboardController {
  @override
  PartnerDashboardState build() {
    // Automatically load data when the provider is built
    unawaited(loadDashboardData());
    return const PartnerDashboardState();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(status: const AsyncValue.loading());

    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) {
        state = state.copyWith(
          status: const AsyncValue.data(null),
          pendingReviewCount: 0,
          todayEvents: [],
          hasRevenuePermission: false,
        );
        return;
      }

      final eventRepo = ref.read(eventRepositoryProvider);
      final partnerRepo = ref.read(partnerRepositoryProvider);

      // 1. Pending Count
      final pendingCount =
          await eventRepo.getPendingApplicationCount(partner.id);

      // 2. Today's Events
      final todayEvents = await eventRepo.getTodayEvents(partner.id);

      // 3. Permission Check
      final memberInfo = await partnerRepo.getMyMemberRole(partner.id);
      final role = memberInfo?['role'] as String?;
      final permissions =
          (memberInfo?['permissions'] as List?)?.cast<String>() ?? [];

      final hasPermission =
          role == 'owner' || permissions.contains('SETTLEMENT_VIEW');

      state = state.copyWith(
        status: const AsyncValue.data(null),
        pendingReviewCount: pendingCount,
        todayEvents: todayEvents,
        hasRevenuePermission: hasPermission,
      );
    } on Exception catch (e, st) {
      state = state.copyWith(status: AsyncValue.error(e, st));
    }
  }
}
