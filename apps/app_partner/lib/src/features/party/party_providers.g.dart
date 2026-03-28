// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_providers.dart';

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
    r'dc58cef67cdb483412a91e1a351db0355d397153';
