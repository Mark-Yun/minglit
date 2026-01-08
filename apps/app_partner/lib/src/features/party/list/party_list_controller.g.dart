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
          AsyncValue<List<Party>>,
          List<Party>,
          FutureOr<List<Party>>
        >
    with $FutureModifier<List<Party>>, $FutureProvider<List<Party>> {
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
  $FutureProviderElement<List<Party>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Party>> create(Ref ref) {
    return partyList(ref);
  }
}

String _$partyListHash() => r'4de4d4ebeab7c61605f25cce03e4fb3a98ac2676';
