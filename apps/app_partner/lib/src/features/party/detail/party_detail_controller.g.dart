// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(partyDetail)
const partyDetailProvider = PartyDetailFamily._();

final class PartyDetailProvider
    extends $FunctionalProvider<AsyncValue<Party>, Party, FutureOr<Party>>
    with $FutureModifier<Party>, $FutureProvider<Party> {
  const PartyDetailProvider._({
    required PartyDetailFamily super.from,
    required String super.argument,
  }) : super(
          retry: null,
          name: r'partyDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$partyDetailHash();

  @override
  String toString() {
    return r'partyDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Party> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Party> create(Ref ref) {
    final argument = this.argument as String;
    return partyDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartyDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partyDetailHash() => r'f5472e03f166441d62e902e46f9652f8fbba70fb';

final class PartyDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Party>, String> {
  const PartyDetailFamily._()
      : super(
          retry: null,
          name: r'partyDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PartyDetailProvider call(String partyId) =>
      PartyDetailProvider._(argument: partyId, from: this);

  @override
  String toString() => r'partyDetailProvider';
}

@ProviderFor(partyTickets)
const partyTicketsProvider = PartyTicketsFamily._();

final class PartyTicketsProvider extends $FunctionalProvider<
        AsyncValue<List<TicketTemplate>>,
        List<TicketTemplate>,
        FutureOr<List<TicketTemplate>>>
    with
        $FutureModifier<List<TicketTemplate>>,
        $FutureProvider<List<TicketTemplate>> {
  const PartyTicketsProvider._({
    required PartyTicketsFamily super.from,
    required String super.argument,
  }) : super(
          retry: null,
          name: r'partyTicketsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$partyTicketsHash();

  @override
  String toString() {
    return r'partyTicketsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TicketTemplate>> $createElement(
    $ProviderPointer pointer,
  ) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TicketTemplate>> create(Ref ref) {
    final argument = this.argument as String;
    return partyTickets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartyTicketsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partyTicketsHash() => r'c456053e7c33bd6f37e486351d5ef0bf5d2523a4';

final class PartyTicketsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TicketTemplate>>, String> {
  const PartyTicketsFamily._()
      : super(
          retry: null,
          name: r'partyTicketsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PartyTicketsProvider call(String partyId) =>
      PartyTicketsProvider._(argument: partyId, from: this);

  @override
  String toString() => r'partyTicketsProvider';
}

@ProviderFor(locationDetail)
const locationDetailProvider = LocationDetailFamily._();

final class LocationDetailProvider extends $FunctionalProvider<
        AsyncValue<Location?>, Location?, FutureOr<Location?>>
    with $FutureModifier<Location?>, $FutureProvider<Location?> {
  const LocationDetailProvider._({
    required LocationDetailFamily super.from,
    required String? super.argument,
  }) : super(
          retry: null,
          name: r'locationDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$locationDetailHash();

  @override
  String toString() {
    return r'locationDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Location?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Location?> create(Ref ref) {
    final argument = this.argument as String?;
    return locationDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LocationDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$locationDetailHash() => r'6a453c5aa63c4007355e0724a0d2a7c342fca60a';

final class LocationDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Location?>, String?> {
  const LocationDetailFamily._()
      : super(
          retry: null,
          name: r'locationDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  LocationDetailProvider call(String? locationId) =>
      LocationDetailProvider._(argument: locationId, from: this);

  @override
  String toString() => r'locationDetailProvider';
}

@ProviderFor(partyVerifications)
const partyVerificationsProvider = PartyVerificationsFamily._();

final class PartyVerificationsProvider extends $FunctionalProvider<
        AsyncValue<List<Verification>>,
        List<Verification>,
        FutureOr<List<Verification>>>
    with
        $FutureModifier<List<Verification>>,
        $FutureProvider<List<Verification>> {
  const PartyVerificationsProvider._({
    required PartyVerificationsFamily super.from,
    required String super.argument,
  }) : super(
          retry: null,
          name: r'partyVerificationsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$partyVerificationsHash();

  @override
  String toString() {
    return r'partyVerificationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Verification>> $createElement(
    $ProviderPointer pointer,
  ) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Verification>> create(Ref ref) {
    final argument = this.argument as String;
    return partyVerifications(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartyVerificationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partyVerificationsHash() =>
    r'f21f00f8dcbb7b1f30752fd5c15c46d9878e7c58';

final class PartyVerificationsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Verification>>, String> {
  const PartyVerificationsFamily._()
      : super(
          retry: null,
          name: r'partyVerificationsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PartyVerificationsProvider call(String partyId) =>
      PartyVerificationsProvider._(argument: partyId, from: this);

  @override
  String toString() => r'partyVerificationsProvider';
}
