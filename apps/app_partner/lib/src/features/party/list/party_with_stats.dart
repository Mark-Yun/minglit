import 'package:minglit_kit/minglit_kit.dart';

/// Party enriched with aggregated event statistics for the list view.
class PartyWithStats {
  const PartyWithStats({
    required this.party,
    required this.completedCount,
    required this.upcomingCount,
    this.nextEvent,
  });

  final Party party;

  /// Events with status == 'completed'.
  final int completedCount;

  /// Scheduled events with start_time > now().
  final int upcomingCount;

  /// The nearest upcoming event, or null if none exists.
  final Event? nextEvent;
}
