// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [SettlementRepository].

@ProviderFor(settlementRepository)
const settlementRepositoryProvider = SettlementRepositoryProvider._();

/// Provider for [SettlementRepository].

final class SettlementRepositoryProvider extends $FunctionalProvider<
    SettlementRepository,
    SettlementRepository,
    SettlementRepository> with $Provider<SettlementRepository> {
  /// Provider for [SettlementRepository].
  const SettlementRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settlementRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settlementRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettlementRepository> $createElement(
    $ProviderPointer pointer,
  ) =>
      $ProviderElement(pointer);

  @override
  SettlementRepository create(Ref ref) {
    return settlementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettlementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettlementRepository>(value),
    );
  }
}

String _$settlementRepositoryHash() =>
    r'9a7653d39c2accaa597f6afd9bef3c8ac3ee6a37';
