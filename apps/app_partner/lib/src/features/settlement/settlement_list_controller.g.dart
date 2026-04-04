// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettlementListController)
const settlementListControllerProvider = SettlementListControllerProvider._();

final class SettlementListControllerProvider
    extends $NotifierProvider<SettlementListController, SettlementListState> {
  const SettlementListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settlementListControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settlementListControllerHash();

  @$internal
  @override
  SettlementListController create() => SettlementListController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettlementListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettlementListState>(value),
    );
  }
}

String _$settlementListControllerHash() =>
    r'64f75af0866f2d373fe2bb0b7aa46d04c64d701a';

abstract class _$SettlementListController
    extends $Notifier<SettlementListState> {
  SettlementListState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SettlementListState, SettlementListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SettlementListState, SettlementListState>,
              SettlementListState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
