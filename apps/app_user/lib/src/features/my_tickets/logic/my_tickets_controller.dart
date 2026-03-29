import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_tickets_controller.g.dart';

/// Fix #639: MyTicketsController — upcoming/past ticket separation + today event detection.
///
/// Fetches active tickets (paid/approved) and splits them by event start time.
@riverpod
class MyTicketsController extends _$MyTicketsController {
  @override
  FutureOr<MyTicketsState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return MyTicketsState(
        upcoming: [],
        past: [],
        todayEvent: null,
      );
    }

    final repository = ref.watch(eventRepositoryProvider);
    final tickets = await repository.getMyTickets(user.id);
    return _splitTickets(tickets);
  }

  MyTicketsState _splitTickets(List<EventApplication> tickets) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final upcoming = <EventApplication>[];
    final past = <EventApplication>[];

    for (final ticket in tickets) {
      final startTime = ticket.event?.startTime;
      if (startTime == null) {
        // No event relation — treat as past
        past.add(ticket);
        continue;
      }
      if (startTime.isAfter(now)) {
        upcoming.add(ticket);
      } else {
        past.add(ticket);
      }
    }

    // upcoming: ascending (nearest first)
    upcoming.sort((a, b) {
      final aTime = a.event!.startTime;
      final bTime = b.event!.startTime;
      return aTime.compareTo(bTime);
    });

    // past: descending (most recent first) — event may be null for orphans
    past.sort((a, b) {
      final aTime = a.event?.startTime ?? DateTime(0);
      final bTime = b.event?.startTime ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    // todayEvent: events starting today, pick the most imminent one
    EventApplication? todayEvent;
    for (final ticket in upcoming) {
      final startTime = ticket.event?.startTime;
      if (startTime != null &&
          !startTime.isBefore(todayStart) &&
          startTime.isBefore(todayEnd)) {
        todayEvent = ticket;
        break; // upcoming is ASC sorted, so first match is most imminent
      }
    }

    return MyTicketsState(
      upcoming: upcoming,
      past: past,
      todayEvent: todayEvent,
    );
  }
}

/// Immutable state holding split ticket lists.
class MyTicketsState {
  MyTicketsState({
    required List<EventApplication> upcoming,
    required List<EventApplication> past,
    required this.todayEvent,
  }) : upcoming = List.unmodifiable(upcoming),
       past = List.unmodifiable(past);

  final List<EventApplication> upcoming;
  final List<EventApplication> past;

  /// The most imminent event starting today, or null.
  final EventApplication? todayEvent;

  // Fix #660: include todayEvent in emptiness check
  bool get isEmpty =>
      upcoming.isEmpty && past.isEmpty && todayEvent == null;
}
