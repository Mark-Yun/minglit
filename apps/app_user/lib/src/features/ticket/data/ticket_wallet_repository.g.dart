// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_wallet_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(secureStorage)
const secureStorageProvider = SecureStorageProvider._();

final class SecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  const SecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return secureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$secureStorageHash() => r'39b6a2355a8398a2c25bb6e7dd3111ede1fc9c9b';

@ProviderFor(ticketWalletRepository)
const ticketWalletRepositoryProvider = TicketWalletRepositoryProvider._();

final class TicketWalletRepositoryProvider
    extends
        $FunctionalProvider<
          TicketWalletRepository,
          TicketWalletRepository,
          TicketWalletRepository
        >
    with $Provider<TicketWalletRepository> {
  const TicketWalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketWalletRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketWalletRepositoryHash();

  @$internal
  @override
  $ProviderElement<TicketWalletRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TicketWalletRepository create(Ref ref) {
    return ticketWalletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketWalletRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketWalletRepository>(value),
    );
  }
}

String _$ticketWalletRepositoryHash() =>
    r'005215b942cee46086092d58eed3c66cb83884ed';
