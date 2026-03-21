// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_apply_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PartnerApplyController)
const partnerApplyControllerProvider = PartnerApplyControllerProvider._();

final class PartnerApplyControllerProvider
    extends $NotifierProvider<PartnerApplyController, PartnerApplyState> {
  const PartnerApplyControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'partnerApplyControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$partnerApplyControllerHash();

  @$internal
  @override
  PartnerApplyController create() => PartnerApplyController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartnerApplyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartnerApplyState>(value),
    );
  }
}

String _$partnerApplyControllerHash() =>
    r'b638e933f5ca954d8303c0a36d01bee7c8dff6ec';

abstract class _$PartnerApplyController extends $Notifier<PartnerApplyState> {
  PartnerApplyState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<PartnerApplyState, PartnerApplyState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PartnerApplyState, PartnerApplyState>,
        PartnerApplyState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
