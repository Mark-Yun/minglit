import 'package:minglit_kit/src/data/models/event.dart';

/// A user's active event for today, combining event data
/// with participant status.
///
/// Used by Event Now Bar to display the user's
/// ongoing/upcoming events.
class TodayActiveEvent {
  /// Creates a [TodayActiveEvent].
  const TodayActiveEvent({
    required this.event,
    required this.participantStatus,
  });

  /// The event data with party, location, and ticket info.
  final Event event;

  /// The user's participant status:
  /// 'ticket_issued', 'checked_in', or 'no_show'.
  final String participantStatus;
}
