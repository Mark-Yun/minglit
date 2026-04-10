// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_token_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticketTokenService)
const ticketTokenServiceProvider = TicketTokenServiceProvider._();

final class TicketTokenServiceProvider
    extends
        $FunctionalProvider<
          TicketTokenService,
          TicketTokenService,
          TicketTokenService
        >
    with $Provider<TicketTokenService> {
  const TicketTokenServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketTokenServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketTokenServiceHash();

  @$internal
  @override
  $ProviderElement<TicketTokenService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TicketTokenService create(Ref ref) {
    return ticketTokenService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketTokenService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketTokenService>(value),
    );
  }
}

String _$ticketTokenServiceHash() =>
    r'4241ffa8747992cfce6d5057e004dcf6d131f229';
