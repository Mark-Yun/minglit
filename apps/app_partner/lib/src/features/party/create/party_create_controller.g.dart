// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_create_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(partyVerificationTypes)
const partyVerificationTypesProvider = PartyVerificationTypesProvider._();

final class PartyVerificationTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Verification>>,
          List<Verification>,
          FutureOr<List<Verification>>
        >
    with
        $FutureModifier<List<Verification>>,
        $FutureProvider<List<Verification>> {
  const PartyVerificationTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partyVerificationTypesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partyVerificationTypesHash();

  @$internal
  @override
  $FutureProviderElement<List<Verification>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Verification>> create(Ref ref) {
    return partyVerificationTypes(ref);
  }
}

String _$partyVerificationTypesHash() =>
    r'7b1b9687d5ccfb84e21ba6efeb572aa268a50838';

@ProviderFor(partnerLocations)
const partnerLocationsProvider = PartnerLocationsFamily._();

final class PartnerLocationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Location>>,
          List<Location>,
          FutureOr<List<Location>>
        >
    with $FutureModifier<List<Location>>, $FutureProvider<List<Location>> {
  const PartnerLocationsProvider._({
    required PartnerLocationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partnerLocationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partnerLocationsHash();

  @override
  String toString() {
    return r'partnerLocationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Location>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Location>> create(Ref ref) {
    final argument = this.argument as String;
    return partnerLocations(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerLocationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerLocationsHash() => r'7f0bf12db48a3a11b0e42005cf5630a77d152a72';

final class PartnerLocationsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Location>>, String> {
  const PartnerLocationsFamily._()
    : super(
        retry: null,
        name: r'partnerLocationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PartnerLocationsProvider call(String partnerId) =>
      PartnerLocationsProvider._(argument: partnerId, from: this);

  @override
  String toString() => r'partnerLocationsProvider';
}

@ProviderFor(currentPartnerInfo)
const currentPartnerInfoProvider = CurrentPartnerInfoProvider._();

final class CurrentPartnerInfoProvider
    extends
        $FunctionalProvider<AsyncValue<Partner?>, Partner?, FutureOr<Partner?>>
    with $FutureModifier<Partner?>, $FutureProvider<Partner?> {
  const CurrentPartnerInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPartnerInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPartnerInfoHash();

  @$internal
  @override
  $FutureProviderElement<Partner?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Partner?> create(Ref ref) {
    return currentPartnerInfo(ref);
  }
}

String _$currentPartnerInfoHash() =>
    r'64d0d3d0355e6eeeeb51602baecfd60eeb6655f5';

@ProviderFor(PartyCreateController)
const partyCreateControllerProvider = PartyCreateControllerProvider._();

final class PartyCreateControllerProvider
    extends $NotifierProvider<PartyCreateController, PartyCreateState> {
  const PartyCreateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partyCreateControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partyCreateControllerHash();

  @$internal
  @override
  PartyCreateController create() => PartyCreateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartyCreateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartyCreateState>(value),
    );
  }
}

String _$partyCreateControllerHash() =>
    r'53718c22fdb117dd6b36b06a8660d7c313b43157';

abstract class _$PartyCreateController extends $Notifier<PartyCreateState> {
  PartyCreateState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<PartyCreateState, PartyCreateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PartyCreateState, PartyCreateState>,
              PartyCreateState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
