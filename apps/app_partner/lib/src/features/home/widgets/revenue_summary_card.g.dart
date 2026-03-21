// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_summary_card.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads current month net settlement amount from SettlementRepository.

@ProviderFor(currentMonthNet)
const currentMonthNetProvider = CurrentMonthNetProvider._();

/// Loads current month net settlement amount from SettlementRepository.

final class CurrentMonthNetProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Loads current month net settlement amount from SettlementRepository.
  const CurrentMonthNetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthNetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthNetHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return currentMonthNet(ref);
  }
}

String _$currentMonthNetHash() => r'c684e86e332e3f63dc7c563172cd5eb8352d8e42';
