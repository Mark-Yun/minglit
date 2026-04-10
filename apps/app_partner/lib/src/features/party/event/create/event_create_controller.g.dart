// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_create_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventCreateController)
const eventCreateControllerProvider = EventCreateControllerFamily._();

final class EventCreateControllerProvider
    extends $NotifierProvider<EventCreateController, EventCreateState> {
  const EventCreateControllerProvider._({
    required EventCreateControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventCreateControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventCreateControllerHash();

  @override
  String toString() {
    return r'eventCreateControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventCreateController create() => EventCreateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventCreateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventCreateState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventCreateControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventCreateControllerHash() =>
    r'794e15feac4e689bb76e094ab6f6a6548d9b7874';

final class EventCreateControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EventCreateController,
          EventCreateState,
          EventCreateState,
          EventCreateState,
          String
        > {
  const EventCreateControllerFamily._()
    : super(
        retry: null,
        name: r'eventCreateControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventCreateControllerProvider call(String partyId) =>
      EventCreateControllerProvider._(argument: partyId, from: this);

  @override
  String toString() => r'eventCreateControllerProvider';
}

abstract class _$EventCreateController extends $Notifier<EventCreateState> {
  late final _$args = ref.$arg as String;
  String get partyId => _$args;

  EventCreateState build(String partyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<EventCreateState, EventCreateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventCreateState, EventCreateState>,
              EventCreateState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
