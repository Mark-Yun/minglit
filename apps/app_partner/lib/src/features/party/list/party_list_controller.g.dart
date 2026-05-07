// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(partyList)
const partyListProvider = PartyListProvider._();

final class PartyListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PartyWithStats>>,
          List<PartyWithStats>,
          FutureOr<List<PartyWithStats>>
        >
    with
        $FutureModifier<List<PartyWithStats>>,
        $FutureProvider<List<PartyWithStats>> {
  const PartyListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partyListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partyListHash();

  @$internal
  @override
  $FutureProviderElement<List<PartyWithStats>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PartyWithStats>> create(Ref ref) {
    return partyList(ref);
  }
}

String _$partyListHash() => r'51de73c23da9f7a034ff969c04d7e5b2f45d34b4';
