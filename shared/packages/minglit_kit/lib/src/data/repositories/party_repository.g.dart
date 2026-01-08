// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for PartyRepository.

@ProviderFor(partyRepository)
const partyRepositoryProvider = PartyRepositoryProvider._();

/// Provider for PartyRepository.

final class PartyRepositoryProvider
    extends
        $FunctionalProvider<PartyRepository, PartyRepository, PartyRepository>
    with $Provider<PartyRepository> {
  /// Provider for PartyRepository.
  const PartyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partyRepositoryHash();

  @$internal
  @override
  $ProviderElement<PartyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PartyRepository create(Ref ref) {
    return partyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartyRepository>(value),
    );
  }
}

String _$partyRepositoryHash() => r'e2446f9baf58b47e39aa61c36b420c6406d071d1';
