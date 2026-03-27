// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches entry groups for a party — ticket-local provider to avoid
/// importing party feature controllers.

@ProviderFor(ticketEntryGroups)
const ticketEntryGroupsProvider = TicketEntryGroupsFamily._();

/// Fetches entry groups for a party — ticket-local provider to avoid
/// importing party feature controllers.

final class TicketEntryGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PartyEntryGroup>>,
          List<PartyEntryGroup>,
          FutureOr<List<PartyEntryGroup>>
        >
    with
        $FutureModifier<List<PartyEntryGroup>>,
        $FutureProvider<List<PartyEntryGroup>> {
  /// Fetches entry groups for a party — ticket-local provider to avoid
  /// importing party feature controllers.
  const TicketEntryGroupsProvider._({
    required TicketEntryGroupsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ticketEntryGroupsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketEntryGroupsHash();

  @override
  String toString() {
    return r'ticketEntryGroupsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PartyEntryGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PartyEntryGroup>> create(Ref ref) {
    final argument = this.argument as String;
    return ticketEntryGroups(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketEntryGroupsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketEntryGroupsHash() => r'2b5c78dc53196305459863cfc8d37f55365b6e93';

/// Fetches entry groups for a party — ticket-local provider to avoid
/// importing party feature controllers.

final class TicketEntryGroupsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PartyEntryGroup>>, String> {
  const TicketEntryGroupsFamily._()
    : super(
        retry: null,
        name: r'ticketEntryGroupsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches entry groups for a party — ticket-local provider to avoid
  /// importing party feature controllers.

  TicketEntryGroupsProvider call(String partyId) =>
      TicketEntryGroupsProvider._(argument: partyId, from: this);

  @override
  String toString() => r'ticketEntryGroupsProvider';
}

/// Fetches ticket templates by party ID — ticket-local provider
/// (mirrors partyTicketsProvider from party feature).

@ProviderFor(ticketTemplatesByParty)
const ticketTemplatesByPartyProvider = TicketTemplatesByPartyFamily._();

/// Fetches ticket templates by party ID — ticket-local provider
/// (mirrors partyTicketsProvider from party feature).

final class TicketTemplatesByPartyProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TicketTemplate>>,
          List<TicketTemplate>,
          FutureOr<List<TicketTemplate>>
        >
    with
        $FutureModifier<List<TicketTemplate>>,
        $FutureProvider<List<TicketTemplate>> {
  /// Fetches ticket templates by party ID — ticket-local provider
  /// (mirrors partyTicketsProvider from party feature).
  const TicketTemplatesByPartyProvider._({
    required TicketTemplatesByPartyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ticketTemplatesByPartyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketTemplatesByPartyHash();

  @override
  String toString() {
    return r'ticketTemplatesByPartyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TicketTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TicketTemplate>> create(Ref ref) {
    final argument = this.argument as String;
    return ticketTemplatesByParty(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketTemplatesByPartyProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketTemplatesByPartyHash() =>
    r'883bcaef340ea5576bcbd013f25eec1a25545ace';

/// Fetches ticket templates by party ID — ticket-local provider
/// (mirrors partyTicketsProvider from party feature).

final class TicketTemplatesByPartyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TicketTemplate>>, String> {
  const TicketTemplatesByPartyFamily._()
    : super(
        retry: null,
        name: r'ticketTemplatesByPartyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches ticket templates by party ID — ticket-local provider
  /// (mirrors partyTicketsProvider from party feature).

  TicketTemplatesByPartyProvider call(String partyId) =>
      TicketTemplatesByPartyProvider._(argument: partyId, from: this);

  @override
  String toString() => r'ticketTemplatesByPartyProvider';
}

/// Fetches tickets by event ID — ticket-local provider
/// (mirrors eventTicketsProvider from party/event feature).

@ProviderFor(ticketsByEvent)
const ticketsByEventProvider = TicketsByEventFamily._();

/// Fetches tickets by event ID — ticket-local provider
/// (mirrors eventTicketsProvider from party/event feature).

final class TicketsByEventProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ticket>>,
          List<Ticket>,
          FutureOr<List<Ticket>>
        >
    with $FutureModifier<List<Ticket>>, $FutureProvider<List<Ticket>> {
  /// Fetches tickets by event ID — ticket-local provider
  /// (mirrors eventTicketsProvider from party/event feature).
  const TicketsByEventProvider._({
    required TicketsByEventFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ticketsByEventProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketsByEventHash();

  @override
  String toString() {
    return r'ticketsByEventProvider'
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
    return ticketsByEvent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketsByEventProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketsByEventHash() => r'b81e544518b20164ea41be345cfc992154935a7a';

/// Fetches tickets by event ID — ticket-local provider
/// (mirrors eventTicketsProvider from party/event feature).

final class TicketsByEventFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Ticket>>, String> {
  const TicketsByEventFamily._()
    : super(
        retry: null,
        name: r'ticketsByEventProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches tickets by event ID — ticket-local provider
  /// (mirrors eventTicketsProvider from party/event feature).

  TicketsByEventProvider call(String eventId) =>
      TicketsByEventProvider._(argument: eventId, from: this);

  @override
  String toString() => r'ticketsByEventProvider';
}
