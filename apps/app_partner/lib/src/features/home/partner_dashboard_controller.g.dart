// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PartnerDashboardController)
const partnerDashboardControllerProvider =
    PartnerDashboardControllerProvider._();

final class PartnerDashboardControllerProvider
    extends
        $NotifierProvider<PartnerDashboardController, PartnerDashboardState> {
  const PartnerDashboardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partnerDashboardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partnerDashboardControllerHash();

  @$internal
  @override
  PartnerDashboardController create() => PartnerDashboardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartnerDashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartnerDashboardState>(value),
    );
  }
}

String _$partnerDashboardControllerHash() =>
    r'e55ba89f0a8a765b258f99c9f19d3c3bc59f35f3';

abstract class _$PartnerDashboardController
    extends $Notifier<PartnerDashboardState> {
  PartnerDashboardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<PartnerDashboardState, PartnerDashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PartnerDashboardState, PartnerDashboardState>,
              PartnerDashboardState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
