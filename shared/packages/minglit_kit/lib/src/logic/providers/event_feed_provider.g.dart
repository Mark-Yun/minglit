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

String _$eventFeedHash() => r'3bdba14c15ee6dd690b3250d33356c918a798b1f';

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
