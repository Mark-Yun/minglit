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
          AsyncValue<List<EventTicket>>,
          List<EventTicket>,
          FutureOr<List<EventTicket>>
        >
    with
        $FutureModifier<List<EventTicket>>,
        $FutureProvider<List<EventTicket>> {
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
  $FutureProviderElement<List<EventTicket>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EventTicket>> create(Ref ref) {
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

String _$partyTicketsHash() => r'513308dc01728b24285dc436b79eda8abc9371f5';

final class PartyTicketsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EventTicket>>, String> {
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
