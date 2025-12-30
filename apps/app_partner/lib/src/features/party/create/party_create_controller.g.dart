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
    r'95e6e487c3d6f5f10d2430675922ab666a4f4c40';

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
    r'34839f99bf0fd231b6579dbf787df7eaaae3359f';

@ProviderFor(PartyCreateController)
const partyCreateControllerProvider = PartyCreateControllerProvider._();

final class PartyCreateControllerProvider
    extends $AsyncNotifierProvider<PartyCreateController, void> {
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
}

String _$partyCreateControllerHash() =>
    r'728fdc80b50c394058898012c50ad5d595945a01';

abstract class _$PartyCreateController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
