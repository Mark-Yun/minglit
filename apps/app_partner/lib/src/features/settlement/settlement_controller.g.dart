// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettlementController)
const settlementControllerProvider = SettlementControllerProvider._();

final class SettlementControllerProvider
    extends $NotifierProvider<SettlementController, SettlementState> {
  const SettlementControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settlementControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settlementControllerHash();

  @$internal
  @override
  SettlementController create() => SettlementController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettlementState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettlementState>(value),
    );
  }
}

String _$settlementControllerHash() =>
    r'4313d200165076521181b77ff99163e207a069d2';

abstract class _$SettlementController extends $Notifier<SettlementState> {
  SettlementState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SettlementState, SettlementState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SettlementState, SettlementState>,
        SettlementState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
