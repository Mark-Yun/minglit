// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventFeed)
const eventFeedProvider = EventFeedFamily._();

final class EventFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  const EventFeedProvider._({
    required EventFeedFamily super.from,
    required ({
      EventFeedType type,
      double? latitude,
      double? longitude,
      int limit,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'eventFeedProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventFeedHash();

  @override
  String toString() {
    return r'eventFeedProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              EventFeedType type,
              double? latitude,
              double? longitude,
              int limit,
            });
    return eventFeed(
      ref,
      type: argument.type,
      latitude: argument.latitude,
      longitude: argument.longitude,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventFeedHash() => r'edcefe3443ef901d69db7f4aa12967e816ef2d00';

final class EventFeedFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Event>>,
          ({EventFeedType type, double? latitude, double? longitude, int limit})
        > {
  const EventFeedFamily._()
    : super(
        retry: null,
        name: r'eventFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  EventFeedProvider call({
    required EventFeedType type,
    double? latitude,
    double? longitude,
    int limit = 10,
  }) => EventFeedProvider._(
    argument: (
      type: type,
      latitude: latitude,
      longitude: longitude,
      limit: limit,
    ),
    from: this,
  );

  @override
  String toString() => r'eventFeedProvider';
}

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
         isAutoDispose: false,
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

String _$eventDetailHash() => r'3bfa5e13d5627ed80090c76e5c86ab97dd4e6d4c';

final class EventDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Event>, String> {
  const EventDetailFamily._()
    : super(
        retry: null,
        name: r'eventDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  EventDetailProvider call(String eventId) =>
      EventDetailProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventDetailProvider';
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
         isAutoDispose: false,
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

String _$partyEventsHash() => r'740314621557dd2a4bdc322a311f3a1b8d4febbb';

final class PartyEventsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Event>>, String> {
  const PartyEventsFamily._()
    : super(
        retry: null,
        name: r'partyEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PartyEventsProvider call(String partyId) =>
      PartyEventsProvider._(argument: partyId, from: this);

  @override
  String toString() => r'partyEventsProvider';
}
