import 'package:minglit_kit/minglit_kit.dart';

enum EventPhase {
  recruiting,
  preStart,
  checkinReady,
  live,
  ended,
}

const partnerCheckinLeadTime = Duration(hours: 2);

EventPhase getEventPhase(Event event) {
  final now = DateTime.now();
  if (now.isAfter(event.endTime)) return EventPhase.ended;
  if (now.isAfter(event.startTime)) return EventPhase.live;
  final untilStart = event.startTime.difference(now);
  if (untilStart <= partnerCheckinLeadTime) {
    return EventPhase.checkinReady;
  }
  if (untilStart <= const Duration(days: 7)) {
    return EventPhase.preStart;
  }
  return EventPhase.recruiting;
}

Event? selectPrimaryEvent(List<Event> events) {
  if (events.isEmpty) return null;

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(hours: 24));
  Event? bestLive;
  Event? bestCheckinReady;
  Event? bestPreStart;
  Event? bestEnded;
  Event? bestRecruiting;

  for (final event in events) {
    switch (getEventPhase(event)) {
      case EventPhase.live:
        if (bestLive == null || event.startTime.isBefore(bestLive.startTime)) {
          bestLive = event;
        }
      case EventPhase.checkinReady:
        if (bestCheckinReady == null ||
            event.startTime.isBefore(bestCheckinReady.startTime)) {
          bestCheckinReady = event;
        }
      case EventPhase.preStart:
        if (bestPreStart == null ||
            event.startTime.isBefore(bestPreStart.startTime)) {
          bestPreStart = event;
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

  return bestLive ??
      bestCheckinReady ??
      bestPreStart ??
      bestEnded ??
      bestRecruiting;
}

bool isOngoingListWindow(Event event) {
  final now = DateTime.now();
  final earlyWindow = event.startTime.subtract(const Duration(days: 7));
  final lateWindow = event.endTime.add(const Duration(hours: 24));
  return now.isAfter(earlyWindow) && now.isBefore(lateWindow);
}

bool isCheckinActionEnabled(Event event) {
  final now = DateTime.now();
  final backendReadyAt = event.startTime.subtract(partnerCheckinLeadTime);
  return !now.isBefore(backendReadyAt) && now.isBefore(event.endTime);
}
