// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventDetail)
const eventDetailProvider = EventDetailFamily._();

final class EventDetailProvider
    extends $FunctionalProvider<AsyncValue<Event>, Event, FutureOr<Event>>
    with $FutureModifier<Event>, $FutureProvider<Event> {
  const EventDetailProvider._({
    required EventDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventDetailHash();

  @override
  String toString() {
    return r'eventDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Event> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Event> create(Ref ref) {
    final argument = this.argument as String;
    return eventDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventDetailHash() => r'55d5a21e61d125438ffd95a0ec2f7121b07ccb1d';

final class EventDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Event>, String> {
  const EventDetailFamily._()
    : super(
        retry: null,
        name: r'eventDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventDetailProvider call(String eventId) =>
      EventDetailProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventDetailProvider';
}

@ProviderFor(eventTickets)
const eventTicketsProvider = EventTicketsFamily._();

final class EventTicketsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EventTicket>>,
          List<EventTicket>,
          FutureOr<List<EventTicket>>
        >
    with
        $FutureModifier<List<EventTicket>>,
        $FutureProvider<List<EventTicket>> {
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
  $FutureProviderElement<List<EventTicket>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EventTicket>> create(Ref ref) {
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

String _$eventTicketsHash() => r'2ed2f839971937a9cc5c42776129748c42624848';

final class EventTicketsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EventTicket>>, String> {
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
