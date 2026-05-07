/// User-facing active event lifecycle states for My Tickets v2.
enum EventLifecyclePhase {
  waiting,
  checkInReady,
  checkedIn,
  matchingReady,
  matching,
  resultsUnviewed,
  resultsViewed,
  noShow,
  ended,
}

/// Sort priority for active event banners.
extension EventLifecyclePhaseSortKey on EventLifecyclePhase {
  int get urgencyRank {
    return switch (this) {
      EventLifecyclePhase.checkInReady ||
      EventLifecyclePhase.matchingReady ||
      EventLifecyclePhase.resultsUnviewed => 1,
      EventLifecyclePhase.matching => 2,
      EventLifecyclePhase.resultsViewed => 3,
      EventLifecyclePhase.checkedIn => 4,
      EventLifecyclePhase.waiting => 5,
      EventLifecyclePhase.noShow => 6,
      EventLifecyclePhase.ended => 7,
    };
  }
}
