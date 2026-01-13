// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_admission_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventAdmissionController)
const eventAdmissionControllerProvider = EventAdmissionControllerFamily._();

final class EventAdmissionControllerProvider
    extends $AsyncNotifierProvider<EventAdmissionController, AdmissionState> {
  const EventAdmissionControllerProvider._({
    required EventAdmissionControllerFamily super.from,
    required Event super.argument,
  }) : super(
         retry: null,
         name: r'eventAdmissionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventAdmissionControllerHash();

  @override
  String toString() {
    return r'eventAdmissionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventAdmissionController create() => EventAdmissionController();

  @override
  bool operator ==(Object other) {
    return other is EventAdmissionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventAdmissionControllerHash() =>
    r'd91ea4229451d9660e1eb8082e6322227de7692e';

final class EventAdmissionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EventAdmissionController,
          AsyncValue<AdmissionState>,
          AdmissionState,
          FutureOr<AdmissionState>,
          Event
        > {
  const EventAdmissionControllerFamily._()
    : super(
        retry: null,
        name: r'eventAdmissionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventAdmissionControllerProvider call(Event event) =>
      EventAdmissionControllerProvider._(argument: event, from: this);

  @override
  String toString() => r'eventAdmissionControllerProvider';
}

abstract class _$EventAdmissionController
    extends $AsyncNotifier<AdmissionState> {
  late final _$args = ref.$arg as Event;
  Event get event => _$args;

  FutureOr<AdmissionState> build(Event event);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<AdmissionState>, AdmissionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AdmissionState>, AdmissionState>,
              AsyncValue<AdmissionState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
