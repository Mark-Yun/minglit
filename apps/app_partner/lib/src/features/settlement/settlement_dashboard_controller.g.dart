// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettlementDashboardController)
const settlementDashboardControllerProvider =
    SettlementDashboardControllerProvider._();

final class SettlementDashboardControllerProvider
    extends
        $NotifierProvider<
          SettlementDashboardController,
          SettlementDashboardState
        > {
  const SettlementDashboardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settlementDashboardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settlementDashboardControllerHash();

  @$internal
  @override
  SettlementDashboardController create() => SettlementDashboardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettlementDashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettlementDashboardState>(value),
    );
  }
}

String _$settlementDashboardControllerHash() =>
    r'3875ecfe7e844ae99318754b7ef9500c025a0f1d';

abstract class _$SettlementDashboardController
    extends $Notifier<SettlementDashboardState> {
  SettlementDashboardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<SettlementDashboardState, SettlementDashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SettlementDashboardState, SettlementDashboardState>,
              SettlementDashboardState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
