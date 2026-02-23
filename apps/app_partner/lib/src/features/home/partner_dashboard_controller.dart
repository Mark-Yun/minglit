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
    @Default([]) List<Event> upcomingEvents,
    @Default([]) List<Event> closingSoonEvents,
    @Default([]) List<Party> activeParties,
    @Default(AsyncValue<void>.loading()) AsyncValue<void> status,
  }) = _PartnerDashboardState;
}

@riverpod
class PartnerDashboardController extends _$PartnerDashboardController {
  @override
  PartnerDashboardState build() {
    // Schedule loading after build() returns so that `state` is initialized.
    // unawaited() runs synchronously until the first await, which would
    // access `state` before build() has returned — causing
    // "Tried to read the state of an uninitialized provider".
    unawaited(Future.microtask(loadDashboardData));
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
          upcomingEvents: [],
          closingSoonEvents: [],
          activeParties: [],
        );
        return;
      }
      final eventRepo = ref.read(eventRepositoryProvider);
      final partyRepo = ref.read(partyRepositoryProvider);
      // 1. Pending Count
      final pendingCount = await eventRepo.getPendingApplicationCount(
        partner.id,
      );

      // 2. Upcoming Events (next 7 days)
      final upcomingEvents = await eventRepo.getUpcomingEvents(partner.id);

      // 3. Closing Soon Events (next 3 days)
      final closingSoonEvents = await eventRepo.getClosingSoonEvents(
        partner.id,
      );

      // 4. Active Parties
      final activeParties = await partyRepo.getPartiesByPartnerId(
        partner.id,
      );

      state = state.copyWith(
        status: const AsyncValue.data(null),
        pendingReviewCount: pendingCount,
        upcomingEvents: upcomingEvents,
        closingSoonEvents: closingSoonEvents,
        activeParties: activeParties,
      );
    } on Exception catch (e, st) {
      state = state.copyWith(status: AsyncValue.error(e, st));
    }
  }
}
