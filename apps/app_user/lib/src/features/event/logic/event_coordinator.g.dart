// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventCoordinator)
const eventCoordinatorProvider = EventCoordinatorProvider._();

final class EventCoordinatorProvider extends $FunctionalProvider<
    EventCoordinator,
    EventCoordinator,
    EventCoordinator> with $Provider<EventCoordinator> {
  const EventCoordinatorProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'eventCoordinatorProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventCoordinatorHash();

  @$internal
  @override
  $ProviderElement<EventCoordinator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventCoordinator create(Ref ref) {
    return eventCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventCoordinator>(value),
    );
  }
}

String _$eventCoordinatorHash() => r'b9f6bca82f6e387e73589115caec92a23d119c6c';
