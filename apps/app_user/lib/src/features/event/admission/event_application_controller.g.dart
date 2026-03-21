// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_application_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventApplicationController)
const eventApplicationControllerProvider = EventApplicationControllerFamily._();

final class EventApplicationControllerProvider extends $NotifierProvider<
    EventApplicationController, EventApplicationState> {
  const EventApplicationControllerProvider._({
    required EventApplicationControllerFamily super.from,
    required Event super.argument,
  }) : super(
          retry: null,
          name: r'eventApplicationControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventApplicationControllerHash();

  @override
  String toString() {
    return r'eventApplicationControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventApplicationController create() => EventApplicationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventApplicationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventApplicationState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventApplicationControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventApplicationControllerHash() =>
    r'85766dc121922cac2f2357d3435a42d31bfa473b';

final class EventApplicationControllerFamily extends $Family
    with
        $ClassFamilyOverride<EventApplicationController, EventApplicationState,
            EventApplicationState, EventApplicationState, Event> {
  const EventApplicationControllerFamily._()
      : super(
          retry: null,
          name: r'eventApplicationControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  EventApplicationControllerProvider call(Event event) =>
      EventApplicationControllerProvider._(argument: event, from: this);

  @override
  String toString() => r'eventApplicationControllerProvider';
}

abstract class _$EventApplicationController
    extends $Notifier<EventApplicationState> {
  late final _$args = ref.$arg as Event;
  Event get event => _$args;

  EventApplicationState build(Event event);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<EventApplicationState, EventApplicationState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<EventApplicationState, EventApplicationState>,
        EventApplicationState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
