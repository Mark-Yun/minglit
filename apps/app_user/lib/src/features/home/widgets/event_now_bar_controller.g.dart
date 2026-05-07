// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_now_bar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns a clock function that produces the current [DateTime].
///
/// The provider returns `() => DateTime.now()` so each call site gets a fresh
/// timestamp instead of a cached value. Override in tests with
/// `() => fixedNow` to make state transitions deterministic.

@ProviderFor(clock)
const clockProvider = ClockProvider._();

/// Returns a clock function that produces the current [DateTime].
///
/// The provider returns `() => DateTime.now()` so each call site gets a fresh
/// timestamp instead of a cached value. Override in tests with
/// `() => fixedNow` to make state transitions deterministic.

final class ClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Returns a clock function that produces the current [DateTime].
  ///
  /// The provider returns `() => DateTime.now()` so each call site gets a fresh
  /// timestamp instead of a cached value. Override in tests with
  /// `() => fixedNow` to make state transitions deterministic.
  const ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$clockHash() => r'3b571c5a0c08b7391c0eed04391003191bab6ccf';

/// Fetches today's active events for the current user.
///
/// Returns events where the user is a participant and the event is within
/// the active window (start_time - 3h to end_time).
/// Cancelled events are included; refunded participants are excluded.

@ProviderFor(todayActiveEvents)
const todayActiveEventsProvider = TodayActiveEventsProvider._();

/// Fetches today's active events for the current user.
///
/// Returns events where the user is a participant and the event is within
/// the active window (start_time - 3h to end_time).
/// Cancelled events are included; refunded participants are excluded.

final class TodayActiveEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TodayActiveEvent>>,
          List<TodayActiveEvent>,
          FutureOr<List<TodayActiveEvent>>
        >
    with
        $FutureModifier<List<TodayActiveEvent>>,
        $FutureProvider<List<TodayActiveEvent>> {
  /// Fetches today's active events for the current user.
  ///
  /// Returns events where the user is a participant and the event is within
  /// the active window (start_time - 3h to end_time).
  /// Cancelled events are included; refunded participants are excluded.
  const TodayActiveEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayActiveEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayActiveEventsHash();

  @$internal
  @override
  $FutureProviderElement<List<TodayActiveEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TodayActiveEvent>> create(Ref ref) {
    return todayActiveEvents(ref);
  }
}

String _$todayActiveEventsHash() => r'712a80f6c5b464779d24767a099715bd53084f10';

/// Computes the [EventNowBarState] for a given event.
///
/// Watches participant status, match candidates, and match results
/// to derive the current state. Guarantees no backward transitions —
/// once a state has been reached, the provider will never return
/// a state with a lower ordinal.

@ProviderFor(EventNowBarStateNotifier)
const eventNowBarStateProvider = EventNowBarStateNotifierFamily._();

/// Computes the [EventNowBarState] for a given event.
///
/// Watches participant status, match candidates, and match results
/// to derive the current state. Guarantees no backward transitions —
/// once a state has been reached, the provider will never return
/// a state with a lower ordinal.
final class EventNowBarStateNotifierProvider
    extends $AsyncNotifierProvider<EventNowBarStateNotifier, EventNowBarState> {
  /// Computes the [EventNowBarState] for a given event.
  ///
  /// Watches participant status, match candidates, and match results
  /// to derive the current state. Guarantees no backward transitions —
  /// once a state has been reached, the provider will never return
  /// a state with a lower ordinal.
  const EventNowBarStateNotifierProvider._({
    required EventNowBarStateNotifierFamily super.from,
    required TodayActiveEvent super.argument,
  }) : super(
         retry: null,
         name: r'eventNowBarStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventNowBarStateNotifierHash();

  @override
  String toString() {
    return r'eventNowBarStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventNowBarStateNotifier create() => EventNowBarStateNotifier();

  @override
  bool operator ==(Object other) {
    return other is EventNowBarStateNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventNowBarStateNotifierHash() =>
    r'2d523ace9700f6f67018e4c9e6e86dfbfe32fa37';

/// Computes the [EventNowBarState] for a given event.
///
/// Watches participant status, match candidates, and match results
/// to derive the current state. Guarantees no backward transitions —
/// once a state has been reached, the provider will never return
/// a state with a lower ordinal.

final class EventNowBarStateNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EventNowBarStateNotifier,
          AsyncValue<EventNowBarState>,
          EventNowBarState,
          FutureOr<EventNowBarState>,
          TodayActiveEvent
        > {
  const EventNowBarStateNotifierFamily._()
    : super(
        retry: null,
        name: r'eventNowBarStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Computes the [EventNowBarState] for a given event.
  ///
  /// Watches participant status, match candidates, and match results
  /// to derive the current state. Guarantees no backward transitions —
  /// once a state has been reached, the provider will never return
  /// a state with a lower ordinal.

  EventNowBarStateNotifierProvider call(TodayActiveEvent activeEvent) =>
      EventNowBarStateNotifierProvider._(argument: activeEvent, from: this);

  @override
  String toString() => r'eventNowBarStateProvider';
}

/// Computes the [EventNowBarState] for a given event.
///
/// Watches participant status, match candidates, and match results
/// to derive the current state. Guarantees no backward transitions —
/// once a state has been reached, the provider will never return
/// a state with a lower ordinal.

abstract class _$EventNowBarStateNotifier
    extends $AsyncNotifier<EventNowBarState> {
  late final _$args = ref.$arg as TodayActiveEvent;
  TodayActiveEvent get activeEvent => _$args;

  FutureOr<EventNowBarState> build(TodayActiveEvent activeEvent);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<EventNowBarState>, EventNowBarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EventNowBarState>, EventNowBarState>,
              AsyncValue<EventNowBarState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Subscribes to Supabase Realtime changes on `event_participants` for a
/// given [eventId]. When a change is received, [todayActiveEventsProvider]
/// is invalidated so the UI refreshes.
///
/// Falls back to 30-second polling if the Realtime connection closes.

@ProviderFor(EventRealtime)
const eventRealtimeProvider = EventRealtimeFamily._();

/// Subscribes to Supabase Realtime changes on `event_participants` for a
/// given [eventId]. When a change is received, [todayActiveEventsProvider]
/// is invalidated so the UI refreshes.
///
/// Falls back to 30-second polling if the Realtime connection closes.
final class EventRealtimeProvider
    extends $NotifierProvider<EventRealtime, void> {
  /// Subscribes to Supabase Realtime changes on `event_participants` for a
  /// given [eventId]. When a change is received, [todayActiveEventsProvider]
  /// is invalidated so the UI refreshes.
  ///
  /// Falls back to 30-second polling if the Realtime connection closes.
  const EventRealtimeProvider._({
    required EventRealtimeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventRealtimeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventRealtimeHash();

  @override
  String toString() {
    return r'eventRealtimeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventRealtime create() => EventRealtime();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventRealtimeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventRealtimeHash() => r'071f128393c0f22c32ba5b47c1df32d438346598';

/// Subscribes to Supabase Realtime changes on `event_participants` for a
/// given [eventId]. When a change is received, [todayActiveEventsProvider]
/// is invalidated so the UI refreshes.
///
/// Falls back to 30-second polling if the Realtime connection closes.

final class EventRealtimeFamily extends $Family
    with $ClassFamilyOverride<EventRealtime, void, void, void, String> {
  const EventRealtimeFamily._()
    : super(
        retry: null,
        name: r'eventRealtimeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Subscribes to Supabase Realtime changes on `event_participants` for a
  /// given [eventId]. When a change is received, [todayActiveEventsProvider]
  /// is invalidated so the UI refreshes.
  ///
  /// Falls back to 30-second polling if the Realtime connection closes.

  EventRealtimeProvider call(String eventId) =>
      EventRealtimeProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventRealtimeProvider';
}

/// Subscribes to Supabase Realtime changes on `event_participants` for a
/// given [eventId]. When a change is received, [todayActiveEventsProvider]
/// is invalidated so the UI refreshes.
///
/// Falls back to 30-second polling if the Realtime connection closes.

abstract class _$EventRealtime extends $Notifier<void> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  void build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    build(_$args);
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
