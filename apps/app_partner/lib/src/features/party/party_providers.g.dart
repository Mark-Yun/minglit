// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'adcc4017e5bc8e8c6c631aa01f98f1b5b4c7a456';

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
    r'405a04fece1db686a01f2cc0011de12de97a0b18';
