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

String _$partyDetailHash() => r'ab0009671554222be57d7b0fd571773c3245cb2c';

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

@ProviderFor(partyEvents)
const partyEventsProvider = PartyEventsFamily._();

final class PartyEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  const PartyEventsProvider._({
    required PartyEventsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partyEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partyEventsHash();

  @override
  String toString() {
    return r'partyEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    final argument = this.argument as String;
    return partyEvents(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartyEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partyEventsHash() => r'a4126d84f089bdd9c10e647b6b77a1a1a4134d15';

final class PartyEventsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Event>>, String> {
  const PartyEventsFamily._()
    : super(
        retry: null,
        name: r'partyEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PartyEventsProvider call(String partyId) =>
      PartyEventsProvider._(argument: partyId, from: this);

  @override
  String toString() => r'partyEventsProvider';
}

@ProviderFor(partyTickets)
const partyTicketsProvider = PartyTicketsFamily._();

final class PartyTicketsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ticket>>,
          List<Ticket>,
          FutureOr<List<Ticket>>
        >
    with $FutureModifier<List<Ticket>>, $FutureProvider<List<Ticket>> {
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
  $FutureProviderElement<List<Ticket>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Ticket>> create(Ref ref) {
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

String _$partyTicketsHash() => r'cca5bb8fdbe5f8126efaa453f3bc34484c529d66';

final class PartyTicketsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Ticket>>, String> {
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

final class LocationDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<Location?>,
          Location?,
          FutureOr<Location?>
        >
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

final class PartyVerificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Verification>>,
          List<Verification>,
          FutureOr<List<Verification>>
        >
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
  ) => $FutureProviderElement(pointer);

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

@ProviderFor(verificationsByIds)
const verificationsByIdsProvider = VerificationsByIdsFamily._();

final class VerificationsByIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Verification>>,
          List<Verification>,
          FutureOr<List<Verification>>
        >
    with
        $FutureModifier<List<Verification>>,
        $FutureProvider<List<Verification>> {
  const VerificationsByIdsProvider._({
    required VerificationsByIdsFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'verificationsByIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$verificationsByIdsHash();

  @override
  String toString() {
    return r'verificationsByIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Verification>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Verification>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return verificationsByIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VerificationsByIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$verificationsByIdsHash() =>
    r'56316be7791e011cb69b886a57a955344090d2d7';

final class VerificationsByIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Verification>>, List<String>> {
  const VerificationsByIdsFamily._()
    : super(
        retry: null,
        name: r'verificationsByIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VerificationsByIdsProvider call(List<String> ids) =>
      VerificationsByIdsProvider._(argument: ids, from: this);

  @override
  String toString() => r'verificationsByIdsProvider';
}
