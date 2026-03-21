// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticketCoordinator)
const ticketCoordinatorProvider = TicketCoordinatorProvider._();

final class TicketCoordinatorProvider extends $FunctionalProvider<
    TicketCoordinator,
    TicketCoordinator,
    TicketCoordinator> with $Provider<TicketCoordinator> {
  const TicketCoordinatorProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ticketCoordinatorProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ticketCoordinatorHash();

  @$internal
  @override
  $ProviderElement<TicketCoordinator> $createElement(
    $ProviderPointer pointer,
  ) =>
      $ProviderElement(pointer);

  @override
  TicketCoordinator create(Ref ref) {
    return ticketCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketCoordinator>(value),
    );
  }
}

String _$ticketCoordinatorHash() => r'ed214aa8f5c24a9426f126aee7403506acf36bec';
