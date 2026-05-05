import 'package:minglit_kit/minglit_kit.dart';

enum EventPhase {
  recruiting,
  preparing,
  live,
  ended,
}

EventPhase getEventPhase(Event event) {
  final now = DateTime.now();
  if (now.isAfter(event.endTime)) return EventPhase.ended;
  if (now.isAfter(event.startTime)) return EventPhase.live;
  if (event.startTime.difference(now).inHours <= 3) {
    return EventPhase.preparing;
  }
  return EventPhase.recruiting;
}

Event? selectPrimaryEvent(List<Event> events) {
  if (events.isEmpty) return null;

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(hours: 24));
  Event? bestLive;
  Event? bestPreparing;
  Event? bestEnded;
  Event? bestRecruiting;

  for (final event in events) {
    switch (getEventPhase(event)) {
      case EventPhase.live:
        if (bestLive == null || event.startTime.isBefore(bestLive.startTime)) {
          bestLive = event;
        }
      case EventPhase.preparing:
        if (bestPreparing == null ||
            event.startTime.isBefore(bestPreparing.startTime)) {
          bestPreparing = event;
        }
      case EventPhase.ended:
        if (event.endTime.isAfter(cutoff)) {
          if (bestEnded == null || event.endTime.isAfter(bestEnded.endTime)) {
            bestEnded = event;
          }
        }
      case EventPhase.recruiting:
        if (bestRecruiting == null ||
            event.startTime.isBefore(bestRecruiting.startTime)) {
          bestRecruiting = event;
        }
    }
  }

  return bestLive ?? bestPreparing ?? bestEnded ?? bestRecruiting;
}
