// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_template_manage_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(partyTicketTemplates)
const partyTicketTemplatesProvider = PartyTicketTemplatesFamily._();

final class PartyTicketTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TicketTemplate>>,
          List<TicketTemplate>,
          FutureOr<List<TicketTemplate>>
        >
    with
        $FutureModifier<List<TicketTemplate>>,
        $FutureProvider<List<TicketTemplate>> {
  const PartyTicketTemplatesProvider._({
    required PartyTicketTemplatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partyTicketTemplatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partyTicketTemplatesHash();

  @override
  String toString() {
    return r'partyTicketTemplatesProvider'
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
    return partyTicketTemplates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartyTicketTemplatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partyTicketTemplatesHash() =>
    r'4fc79195b07ef05c1d04ce7153e2271769317edc';

final class PartyTicketTemplatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TicketTemplate>>, String> {
  const PartyTicketTemplatesFamily._()
    : super(
        retry: null,
        name: r'partyTicketTemplatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PartyTicketTemplatesProvider call(String partyId) =>
      PartyTicketTemplatesProvider._(argument: partyId, from: this);

  @override
  String toString() => r'partyTicketTemplatesProvider';
}
