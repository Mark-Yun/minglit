// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_manage_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(partyTickets)
const partyTicketsProvider = PartyTicketsFamily._();

final class PartyTicketsProvider extends $FunctionalProvider<
        AsyncValue<List<Ticket>>, List<Ticket>, FutureOr<List<Ticket>>>
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
  ) =>
      $FutureProviderElement(pointer);

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

String _$partyTicketsHash() => r'4ba35ae993c1f1cd573d41bc872318a0d541425d';

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

  PartyTicketsProvider call(String eventId) =>
      PartyTicketsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'partyTicketsProvider';
}
