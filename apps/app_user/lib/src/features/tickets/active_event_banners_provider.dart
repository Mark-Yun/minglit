import 'dart:async';

import 'package:minglit_kit/minglit_kit.dart';

typedef ActiveEventBannerItem = ({
  EventApplication application,
  EventLifecyclePhase phase,
});

final activeEventBannersProvider = FutureProvider<List<ActiveEventBannerItem>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];

  final eventRepository = ref.watch(eventRepositoryProvider);
  final matchingRepository = ref.watch(matchingRepositoryProvider);

  final (applications, todayActiveEvents) = await (
    eventRepository.getMyTickets(user.id),
    eventRepository.getTodayActiveEventsForUser(user.id),
  ).wait;

  final participantStatusByEventId = {
    for (final item in todayActiveEvents) item.event.id: item.participantStatus,
  };

  final now = DateTime.now();
  final resolved = await Future.wait(
    applications.map((application) async {
      final event = application.event;
      if (event == null) {
        return (
          application: application,
          phase: EventLifecyclePhase.ended,
        );
      }

      final participantStatus = participantStatusByEventId[event.id];
      final isCheckedIn = participantStatus == 'checked_in';
      final isNoShow = participantStatus == 'no_show';

      var hasMatchResults = false;
      var hasMatchingCandidates = false;
      var hasSubmittedVotes = false;
      try {
        final matches = await matchingRepository.getMyMatches(event.id);
        hasMatchResults = matches.isNotEmpty;
      } on Exception catch (e, st) {
        // Propagate matching fetch errors so the provider surfaces error state
        // rather than silently downgrading to a wrong phase.
        Error.throwWithStackTrace(e, st);
      }
      // Only fetch matching state when checked-in to avoid unnecessary calls.
      // Fix #2123: matchingReady → matching requires at least one submitted vote.
      if (isCheckedIn) {
        try {
          final (candidates, voteCount) = await (
            matchingRepository.getMatchingCandidates(event.id),
            matchingRepository.getMyVoteCount(event.id),
          ).wait;
          hasMatchingCandidates = candidates.isNotEmpty;
          hasSubmittedVotes = voteCount > 0;
        } on Object catch (e) {
          Log.w('⚠️ [ActiveBanners] matching state fetch failed for ${event.id}: $e');
        }
      }

      final phase = _resolveEventLifecyclePhase(
        application: application,
        now: now,
        isCheckedIn: isCheckedIn,
        isNoShow: isNoShow,
        hasMatchResults: hasMatchResults,
        hasMatchingCandidates: hasMatchingCandidates,
        hasSubmittedVotes: hasSubmittedVotes,
      );
      return (application: application, phase: phase);
    }),
  );

  final filtered =
      resolved.where((item) => item.phase != EventLifecyclePhase.ended).toList()
        ..sort((a, b) {
          final rankCompare = a.phase.urgencyRank.compareTo(
            b.phase.urgencyRank,
          );
          if (rankCompare != 0) return rankCompare;
          final aTime = a.application.event?.startTime ?? DateTime(0);
          final bTime = b.application.event?.startTime ?? DateTime(0);
          return aTime.compareTo(bTime);
        });

  return filtered;
});

EventLifecyclePhase _resolveEventLifecyclePhase({
  required EventApplication application,
  required DateTime now,
  required bool isCheckedIn,
  required bool isNoShow,
  required bool hasMatchResults,
  required bool hasMatchingCandidates,
  required bool hasSubmittedVotes,
}) {
  final event = application.event;
  if (event == null) return EventLifecyclePhase.ended;

  if (isNoShow) return EventLifecyclePhase.noShow;

  final isCompletedLike =
      event.status == 'completed' ||
      event.status == 'cancelled' ||
      !event.endTime.isAfter(now);

  if (isCompletedLike) {
    if (isCheckedIn || hasMatchResults) {
      return application.matchResultsViewedAt == null
          ? EventLifecyclePhase.resultsUnviewed
          : EventLifecyclePhase.resultsViewed;
    }
    return EventLifecyclePhase.ended;
  }

  if (hasMatchResults) {
    return application.matchResultsViewedAt == null
        ? EventLifecyclePhase.resultsUnviewed
        : EventLifecyclePhase.resultsViewed;
  }

  if (isCheckedIn && event.status == 'ongoing') {
    // Fix #2123: matchingReady → matching only after user submits at least one
    // vote. Candidate availability alone does not indicate the user took action.
    if (hasSubmittedVotes) return EventLifecyclePhase.matching;
    if (hasMatchingCandidates) return EventLifecyclePhase.matchingReady;
  }

  if (isCheckedIn) return EventLifecyclePhase.checkedIn;

  final isCheckInWindow =
      event.status == 'active' ||
      event.status == 'ongoing' ||
      !now.isBefore(event.startTime);
  if (isCheckInWindow) return EventLifecyclePhase.checkInReady;

  return EventLifecyclePhase.waiting;
}
