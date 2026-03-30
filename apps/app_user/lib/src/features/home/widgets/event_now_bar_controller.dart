import 'dart:async';

import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'event_now_bar_controller.g.dart';

/// 6-state lifecycle for Event Now Bar.
///
/// States flow strictly forward: WAITING → CHECK_IN_READY → CHECKED_IN
/// → MATCHING → RESULTS → ENDED. Backward transitions are not allowed.
enum EventNowBarState {
  /// Before the event starts (up to 3h prior).
  waiting,

  /// Event start time reached, user has not checked in yet.
  checkInReady,

  /// User has checked in, waiting for matching to begin.
  checkedIn,

  /// Match candidates are available for voting.
  matching,

  /// Matching results exist (including empty results).
  results,

  /// Event is completed or cancelled.
  ended,
}

/// Fetches today's active events for the current user.
///
/// Returns events where the user is a participant and the event is within
/// the active window (start_time - 3h to end_time).
/// Cancelled events are included; refunded participants are excluded.
@riverpod
Future<List<TodayActiveEvent>> todayActiveEvents(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(eventRepositoryProvider);
  return repository.getTodayActiveEventsForUser(user.id);
}

/// Computes the [EventNowBarState] for a given event.
///
/// Watches participant status, match candidates, and match results
/// to derive the current state. Guarantees no backward transitions —
/// once a state has been reached, the provider will never return
/// a state with a lower ordinal.
@riverpod
class EventNowBarStateNotifier extends _$EventNowBarStateNotifier {
  /// Tracks the highest state ever reached to prevent backward transitions.
  EventNowBarState _highWaterMark = EventNowBarState.waiting;

  @override
  FutureOr<EventNowBarState> build(TodayActiveEvent activeEvent) async {
    final event = activeEvent.event;

    // Compute the raw state from current data.
    final rawState = await _computeState(event, activeEvent.participantStatus);

    // Enforce forward-only transitions.
    if (rawState.index > _highWaterMark.index) {
      _highWaterMark = rawState;
    }

    return _highWaterMark;
  }

  Future<EventNowBarState> _computeState(
    Event event,
    String participantStatus,
  ) async {
    // ENDED: event is completed or cancelled.
    if (event.status == 'completed' || event.status == 'cancelled') {
      return EventNowBarState.ended;
    }

    // RESULTS: myMatchesProvider has results (including empty list means
    // matching round completed).
    try {
      final matches = await ref.watch(myMatchesProvider(event.id).future);
      if (matches.isNotEmpty) {
        return EventNowBarState.results;
      }
    } on Object catch (_) {
      // myMatches not available yet — continue to check lower states.
    }

    // MATCHING: matchCandidatesProvider returns non-empty list.
    try {
      final candidates = await ref.watch(
        matchCandidatesProvider(event.id).future,
      );
      if (candidates.isNotEmpty) {
        return EventNowBarState.matching;
      }
    } on Object catch (_) {
      // matchCandidates not available yet — continue to check lower states.
    }

    // CHECKED_IN: participant has checked in.
    if (participantStatus == 'checked_in') {
      return EventNowBarState.checkedIn;
    }

    // CHECK_IN_READY: event start time has been reached.
    final now = DateTime.now();
    if (!now.isBefore(event.startTime)) {
      return EventNowBarState.checkInReady;
    }

    // WAITING: default — before event starts.
    return EventNowBarState.waiting;
  }

  /// Resets the high water mark. Exposed for testing only.
  // coverage:ignore-start
  void resetHighWaterMarkForTesting() {
    _highWaterMark = EventNowBarState.waiting;
  }

  // coverage:ignore-end
}

/// Subscribes to Supabase Realtime changes on `event_participants` for a
/// given [eventId]. When a change is received, [todayActiveEventsProvider]
/// is invalidated so the UI refreshes.
///
/// Falls back to 30-second polling if the Realtime connection closes.
@riverpod
class EventRealtime extends _$EventRealtime {
  RealtimeChannel? _channel;
  Timer? _pollingTimer;

  @override
  void build(String eventId) {
    final supabase = ref.watch(supabaseClientProvider);

    _channel = supabase.channel('event-now-$eventId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: eventId,
          ),
          callback: (payload) {
            // Invalidate today active events to trigger
            // state recalculation.
            ref.invalidate(todayActiveEventsProvider);
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.closed) {
            _startPollingFallback();
          }
        });

    ref.onDispose(() {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      unawaited(_channel?.unsubscribe());
      _channel = null;
    });
  }

  void _startPollingFallback() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(todayActiveEventsProvider),
    );
  }
}
