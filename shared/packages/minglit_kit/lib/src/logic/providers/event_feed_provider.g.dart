// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **Raw Data Provider**
/// Fetches event data from the server.
/// Uses [keepAlive] with a timer to prevent excessive API calls.

@ProviderFor(fetchEventFeed)
const fetchEventFeedProvider = FetchEventFeedFamily._();

/// **Raw Data Provider**
/// Fetches event data from the server.
/// Uses [keepAlive] with a timer to prevent excessive API calls.

final class FetchEventFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// **Raw Data Provider**
  /// Fetches event data from the server.
  /// Uses [keepAlive] with a timer to prevent excessive API calls.
  const FetchEventFeedProvider._({
    required FetchEventFeedFamily super.from,
    required ({
      EventFeedType type,
      double? latitude,
      double? longitude,
      int limit,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'fetchEventFeedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchEventFeedHash();

  @override
  String toString() {
    return r'fetchEventFeedProvider'
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
    return fetchEventFeed(
      ref,
      type: argument.type,
      latitude: argument.latitude,
      longitude: argument.longitude,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FetchEventFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchEventFeedHash() => r'61d080909ff14a17a73dad68efed9ce67af97053';

/// **Raw Data Provider**
/// Fetches event data from the server.
/// Uses [keepAlive] with a timer to prevent excessive API calls.

final class FetchEventFeedFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Event>>,
          ({EventFeedType type, double? latitude, double? longitude, int limit})
        > {
  const FetchEventFeedFamily._()
    : super(
        retry: null,
        name: r'fetchEventFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// **Raw Data Provider**
  /// Fetches event data from the server.
  /// Uses [keepAlive] with a timer to prevent excessive API calls.

  FetchEventFeedProvider call({
    required EventFeedType type,
    double? latitude,
    double? longitude,
    int limit = 10,
  }) => FetchEventFeedProvider._(
    argument: (
      type: type,
      latitude: latitude,
      longitude: longitude,
      limit: limit,
    ),
    from: this,
  );

  @override
  String toString() => r'fetchEventFeedProvider';
}

/// **View Model Provider**
/// Filters the raw event feed based on the current user's status.
/// This provider re-computes when user profile changes, but DOES NOT trigger a new API call
/// because it watches the cached [fetchEventFeedProvider].

@ProviderFor(eventFeed)
const eventFeedProvider = EventFeedFamily._();

/// **View Model Provider**
/// Filters the raw event feed based on the current user's status.
/// This provider re-computes when user profile changes, but DOES NOT trigger a new API call
/// because it watches the cached [fetchEventFeedProvider].

final class EventFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// **View Model Provider**
  /// Filters the raw event feed based on the current user's status.
  /// This provider re-computes when user profile changes, but DOES NOT trigger a new API call
  /// because it watches the cached [fetchEventFeedProvider].
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
         isAutoDispose: true,
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

String _$eventFeedHash() => r'1b9fbcad96d823160132f80635edecde94436961';

/// **View Model Provider**
/// Filters the raw event feed based on the current user's status.
/// This provider re-computes when user profile changes, but DOES NOT trigger a new API call
/// because it watches the cached [fetchEventFeedProvider].

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
        isAutoDispose: true,
      );

  /// **View Model Provider**
  /// Filters the raw event feed based on the current user's status.
  /// This provider re-computes when user profile changes, but DOES NOT trigger a new API call
  /// because it watches the cached [fetchEventFeedProvider].

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

String _$eventDetailHash() => r'4757ee178863a90cb5e11b6c9e991d64243b8c04';

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

String _$partyEventsHash() => r'867f764853cc62e85763820f8941da007b1c409c';

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
