/// Boarding pass status based on event start time compared to today's date.
///
/// Date comparison uses **local timezone** (not UTC) per spec requirement.
enum BoardingPassStatus {
  /// Event starts today — user should present QR at the gate.
  boarding,

  /// Event starts in the future (tomorrow or later).
  confirmed,

  /// Event was in the past (started yesterday or earlier).
  used,
}

/// Determines the [BoardingPassStatus] for an event starting at
/// [eventStartTime].
///
/// The comparison is day-based (local timezone), not time-based:
/// - Any event starting today (00:00–23:59) → [BoardingPassStatus.boarding]
/// - Any event starting tomorrow or later → [BoardingPassStatus.confirmed]
/// - Any event that started yesterday or earlier → [BoardingPassStatus.used]
///
/// [now] can be overridden for testing. Defaults to [DateTime.now()].
BoardingPassStatus boardingPassStatus(
  DateTime eventStartTime, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  // Day boundaries in local timezone
  final todayStart = DateTime(current.year, current.month, current.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));

  if (eventStartTime.isBefore(todayStart)) {
    return BoardingPassStatus.used;
  } else if (eventStartTime.isBefore(tomorrowStart)) {
    return BoardingPassStatus.boarding;
  } else {
    return BoardingPassStatus.confirmed;
  }
}
