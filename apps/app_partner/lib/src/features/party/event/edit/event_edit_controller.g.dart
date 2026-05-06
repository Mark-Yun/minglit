// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventEditController)
const eventEditControllerProvider = EventEditControllerFamily._();

final class EventEditControllerProvider
    extends $AsyncNotifierProvider<EventEditController, EventEditState> {
  const EventEditControllerProvider._({
    required EventEditControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventEditControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventEditControllerHash();

  @override
  String toString() {
    return r'eventEditControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventEditController create() => EventEditController();

  @override
  bool operator ==(Object other) {
    return other is EventEditControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventEditControllerHash() =>
    r'd1453033791ed59cd7fab1ae9aabe7b0c9a0f647';

final class EventEditControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EventEditController,
          AsyncValue<EventEditState>,
          EventEditState,
          FutureOr<EventEditState>,
          String
        > {
  const EventEditControllerFamily._()
    : super(
        retry: null,
        name: r'eventEditControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventEditControllerProvider call(String eventId) =>
      EventEditControllerProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventEditControllerProvider';
}

abstract class _$EventEditController extends $AsyncNotifier<EventEditState> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<EventEditState> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<EventEditState>, EventEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EventEditState>, EventEditState>,
              AsyncValue<EventEditState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
