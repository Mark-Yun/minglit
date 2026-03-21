// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for PartnerRepository.

@ProviderFor(partnerRepository)
const partnerRepositoryProvider = PartnerRepositoryProvider._();

/// Provider for PartnerRepository.

final class PartnerRepositoryProvider
    extends
        $FunctionalProvider<
          PartnerRepository,
          PartnerRepository,
          PartnerRepository
        >
    with $Provider<PartnerRepository> {
  /// Provider for PartnerRepository.
  const PartnerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partnerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partnerRepositoryHash();

  @$internal
  @override
  $ProviderElement<PartnerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PartnerRepository create(Ref ref) {
    return partnerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartnerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartnerRepository>(value),
    );
  }
}

String _$partnerRepositoryHash() => r'dff0609581634b39ce24f0de4e04bf81c65c5fbd';
