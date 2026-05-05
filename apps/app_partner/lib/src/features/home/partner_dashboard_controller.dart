import 'dart:async';

import 'package:app_partner/src/features/home/home_event_phase.dart';
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
    @Default([]) List<Event> liveEvents,
    @Default([]) List<Event> recruitingEvents,
    @Default([]) List<Event> preparingEvents,
    @Default([]) List<Party> activeParties,
    @Default([]) List<Party> draftParties,
    @Default(0) int totalPartyCount,
    @Default(0) int totalAttendees,
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
    // Fix #1943: watch shared refresh signal — bumped by
    // event_create_controller after successful creation, triggering
    // auto-rebuild without cross-feature coupling.
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
          liveEvents: [],
          recruitingEvents: [],
          preparingEvents: [],
          activeParties: [],
          draftParties: [],
          totalPartyCount: 0,
          totalAttendees: 0,
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

      // Fix #2219: use getEventsByPartnerId (gt end_time) so liveEvents is populated.
      // getUpcomingEvents (gte start_time, 7-day window) excludes started events,
      // making liveEvents always empty and overview counts too low.
      final upcomingEvents = await eventRepo.getEventsByPartnerId(partner.id);

      // 3. Active Parties
      final activeParties = await partyRepo.getPartiesByPartnerId(
        partner.id,
      );

      // 4. Has Any Events (all-time, for onboarding gate)
      // Fix #1215: onboarding must not reappear once partner has ever created
      // an event — getUpcomingEvents only covers next 7 days.
      final hasAnyEvents = await eventRepo.getHasAnyEvents(partner.id);

      final liveEvents = upcomingEvents
          .where((event) => getEventPhase(event) == EventPhase.live)
          .toList();
      final recruitingEvents = upcomingEvents
          .where((event) => getEventPhase(event) == EventPhase.recruiting)
          .toList();
      // Fix #2219: preparing events derived from upcomingEvents (start <3h),
      // not from closingSoonEvents (next 3 days) — keeps derived state in controller.
      final preparingEvents = upcomingEvents
          .where((event) => getEventPhase(event) == EventPhase.preparing)
          .toList();
      final draftParties = activeParties
          .where(
            (party) =>
                upcomingEvents.every((event) => event.partyId != party.id),
          )
          .toList();
      // spec: 참가예정 고객 = 활성화된 이벤트의 누적 결제 완료 참가자 수
      final totalAttendees = upcomingEvents.fold<int>(
        0,
        (sum, event) => sum + event.currentParticipants,
      );

      if (!ref.mounted) return;
      state = state.copyWith(
        status: const AsyncValue.data(null),
        pendingReviewCount: pendingCount,
        upcomingEvents: upcomingEvents,
        liveEvents: liveEvents,
        recruitingEvents: recruitingEvents,
        preparingEvents: preparingEvents,
        activeParties: activeParties,
        draftParties: draftParties,
        totalPartyCount: activeParties.length,
        totalAttendees: totalAttendees,
        hasAnyEvents: hasAnyEvents,
      );
    } on Exception catch (e, st) {
      if (!ref.mounted) return;
      state = state.copyWith(status: AsyncValue.error(e, st));
    }
  }
}
