import 'dart:async';

import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/logic/dashboard_refresh_notifier.dart';
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
    // Fix #1215: tracks ALL events ever created, not just upcoming ones.
    // Using upcomingEvents for onboarding check caused the guide to reappear
    // after all events ended or were more than 7 days away.
    @Default(false) bool hasAnyEvents,
    @Default(AsyncValue<void>.loading()) AsyncValue<void> status,
  }) = _PartnerDashboardState;
}

@riverpod
class PartnerDashboardController extends _$PartnerDashboardController {
  @override
  PartnerDashboardState build() {
    // Fix #1943: watch shared refresh signal — bumped by event_create_controller
    // after successful creation, triggering auto-rebuild without cross-feature coupling.
    ref.watch(dashboardRefreshProvider);
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
      // Fix #1264: invalidation 후 진행 중인 로드가 disposed 인스턴스에 state를 쓰지 않도록
      if (!ref.mounted) return;
      if (partner == null) {
        state = state.copyWith(
          status: const AsyncValue.data(null),
          pendingReviewCount: 0,
          upcomingEvents: [],
          closingSoonEvents: [],
          activeParties: [],
          hasAnyEvents: false,
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

      // 5. Has Any Events (all-time, for onboarding gate)
      // Fix #1215: onboarding must not reappear once partner has ever created
      // an event — getUpcomingEvents only covers next 7 days.
      final hasAnyEvents = await eventRepo.getHasAnyEvents(partner.id);

      if (!ref.mounted) return;
      state = state.copyWith(
        status: const AsyncValue.data(null),
        pendingReviewCount: pendingCount,
        upcomingEvents: upcomingEvents,
        closingSoonEvents: closingSoonEvents,
        activeParties: activeParties,
        hasAnyEvents: hasAnyEvents,
      );
    } on Exception catch (e, st) {
      if (!ref.mounted) return;
      state = state.copyWith(status: AsyncValue.error(e, st));
    }
  }
}
