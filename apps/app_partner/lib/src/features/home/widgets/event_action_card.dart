import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Phase of an event relative to the current time.
enum EventPhase { recruiting, preparing, live, ended }

/// Returns the [EventPhase] for [event] based on [now].
///
/// Phase boundaries (measured from [event.startTime]):
/// - recruiting : startTime is more than 3 hours away
/// - preparing  : startTime is between 0 and 3 hours away (exclusive 3h boundary → preparing)
/// - live       : startTime has passed but endTime has not
/// - ended      : endTime has passed
EventPhase getEventPhase(Event event, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final minutesUntilStart =
      event.startTime.difference(reference).inMinutes;

  if (reference.isAfter(event.endTime)) {
    return EventPhase.ended;
  }
  if (reference.isAfter(event.startTime) ||
      reference.isAtSameMomentAs(event.startTime)) {
    return EventPhase.live;
  }
  // startTime is in the future
  if (minutesUntilStart > 180) {
    return EventPhase.recruiting;
  }
  return EventPhase.preparing;
}

/// Selects the most action-relevant event from [events] using [now].
///
/// Priority:
/// 1. live  — ongoing right now
/// 2. preparing — starting within 3 hours
/// 3. ended — finished within the last 24 hours (most recent first)
/// 4. recruiting — furthest-future filtered out, nearest startTime first
///
/// Returns null when [events] is empty or all ended events are older than 24 h.
Event? selectPrimaryEvent(List<Event> events, {DateTime? now}) {
  if (events.isEmpty) return null;

  final reference = now ?? DateTime.now();

  Event? liveEvent;
  Event? preparingEvent;
  Event? recentEndedEvent;
  Event? recruitingEvent;

  for (final event in events) {
    final phase = getEventPhase(event, now: reference);
    switch (phase) {
      case EventPhase.live:
        liveEvent ??= event;
      case EventPhase.preparing:
        if (preparingEvent == null ||
            event.startTime.isBefore(preparingEvent.startTime)) {
          preparingEvent = event;
        }
      case EventPhase.ended:
        final hoursAgo =
            reference.difference(event.endTime).inHours;
        if (hoursAgo < 24) {
          if (recentEndedEvent == null ||
              event.endTime.isAfter(recentEndedEvent.endTime)) {
            recentEndedEvent = event;
          }
        }
      case EventPhase.recruiting:
        if (recruitingEvent == null ||
            event.startTime.isBefore(recruitingEvent.startTime)) {
          recruitingEvent = event;
        }
    }
  }

  return liveEvent ?? preparingEvent ?? recentEndedEvent ?? recruitingEvent;
}

/// Action card that surfaces the most relevant event and its primary CTA.
class EventActionCard extends StatelessWidget {
  const EventActionCard({
    required this.events,
    required this.onEventTap,
    super.key,
  });

  final List<Event> events;
  final void Function(Event event) onEventTap;

  @override
  Widget build(BuildContext context) {
    final primary = selectPrimaryEvent(events);
    if (primary == null) return const SizedBox.shrink();

    final phase = getEventPhase(primary);
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () => onEventTap(primary),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  primary.title ?? '이벤트',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              _PhaseBadge(phase: phase),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});

  final EventPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      EventPhase.live => ('진행중', Colors.green),
      EventPhase.preparing => ('준비중', Colors.orange),
      EventPhase.ended => ('종료', Colors.grey),
      EventPhase.recruiting => ('모집중', Colors.blue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
