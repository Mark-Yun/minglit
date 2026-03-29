// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_now_bar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
