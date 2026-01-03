// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_create_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventCreateController)
const eventCreateControllerProvider = EventCreateControllerProvider._();

final class EventCreateControllerProvider
    extends $AsyncNotifierProvider<EventCreateController, void> {
  const EventCreateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventCreateControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventCreateControllerHash();

  @$internal
  @override
  EventCreateController create() => EventCreateController();
}

String _$eventCreateControllerHash() =>
    r'efa1183644de62d86cd9a13e0e60b826f2bc717e';

abstract class _$EventCreateController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
