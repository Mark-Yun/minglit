// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettlementCoordinator)
const settlementCoordinatorProvider = SettlementCoordinatorProvider._();

final class SettlementCoordinatorProvider
    extends $NotifierProvider<SettlementCoordinator, void> {
  const SettlementCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settlementCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settlementCoordinatorHash();

  @$internal
  @override
  SettlementCoordinator create() => SettlementCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$settlementCoordinatorHash() =>
    r'90345138923ae890998b40208a23dbd96ea74738';

abstract class _$SettlementCoordinator extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
