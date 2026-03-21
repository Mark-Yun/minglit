// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_detail_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(partyDetailCoordinator)
const partyDetailCoordinatorProvider = PartyDetailCoordinatorProvider._();

final class PartyDetailCoordinatorProvider
    extends
        $FunctionalProvider<
          PartyDetailCoordinator,
          PartyDetailCoordinator,
          PartyDetailCoordinator
        >
    with $Provider<PartyDetailCoordinator> {
  const PartyDetailCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partyDetailCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partyDetailCoordinatorHash();

  @$internal
  @override
  $ProviderElement<PartyDetailCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PartyDetailCoordinator create(Ref ref) {
    return partyDetailCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartyDetailCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartyDetailCoordinator>(value),
    );
  }
}

String _$partyDetailCoordinatorHash() =>
    r'836a8c6a48415ac1a905c714f80110adedcff3e3';
