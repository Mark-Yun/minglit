// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventTickets)
const eventTicketsProvider = EventTicketsFamily._();

final class EventTicketsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ticket>>,
          List<Ticket>,
          FutureOr<List<Ticket>>
        >
    with $FutureModifier<List<Ticket>>, $FutureProvider<List<Ticket>> {
  const EventTicketsProvider._({
    required EventTicketsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventTicketsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventTicketsHash();

  @override
  String toString() {
    return r'eventTicketsProvider'
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
    return eventTickets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventTicketsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventTicketsHash() => r'292ea4381aa7f017c1a785d41309452e93af279c';

final class EventTicketsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Ticket>>, String> {
  const EventTicketsFamily._()
    : super(
        retry: null,
        name: r'eventTicketsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventTicketsProvider call(String eventId) =>
      EventTicketsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventTicketsProvider';
}
