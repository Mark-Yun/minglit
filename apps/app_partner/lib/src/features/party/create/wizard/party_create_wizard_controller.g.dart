// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_create_wizard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PartyCreateWizardController)
const partyCreateWizardControllerProvider =
    PartyCreateWizardControllerProvider._();

final class PartyCreateWizardControllerProvider
    extends
        $NotifierProvider<PartyCreateWizardController, PartyCreateWizardState> {
  const PartyCreateWizardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partyCreateWizardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partyCreateWizardControllerHash();

  @$internal
  @override
  PartyCreateWizardController create() => PartyCreateWizardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartyCreateWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartyCreateWizardState>(value),
    );
  }
}

String _$partyCreateWizardControllerHash() =>
    r'0312095e7207e88369a450463a7c67c0edaa6699';

abstract class _$PartyCreateWizardController
    extends $Notifier<PartyCreateWizardState> {
  PartyCreateWizardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<PartyCreateWizardState, PartyCreateWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PartyCreateWizardState, PartyCreateWizardState>,
              PartyCreateWizardState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
