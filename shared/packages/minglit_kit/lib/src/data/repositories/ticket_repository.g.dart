// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticketRepository)
const ticketRepositoryProvider = TicketRepositoryProvider._();

final class TicketRepositoryProvider
    extends
        $FunctionalProvider<
          TicketRepository,
          TicketRepository,
          TicketRepository
        >
    with $Provider<TicketRepository> {
  const TicketRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketRepositoryHash();

  @$internal
  @override
  $ProviderElement<TicketRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TicketRepository create(Ref ref) {
    return ticketRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketRepository>(value),
    );
  }
}

String _$ticketRepositoryHash() => r'1c96408f331fad4736a37570d8f54ac0a09ba297';
