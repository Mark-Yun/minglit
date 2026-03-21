// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_my_application_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventMyApplication)
const eventMyApplicationProvider = EventMyApplicationFamily._();

final class EventMyApplicationProvider extends $FunctionalProvider<
        AsyncValue<EventApplication?>,
        EventApplication?,
        FutureOr<EventApplication?>>
    with
        $FutureModifier<EventApplication?>,
        $FutureProvider<EventApplication?> {
  const EventMyApplicationProvider._({
    required EventMyApplicationFamily super.from,
    required String super.argument,
  }) : super(
          retry: null,
          name: r'eventMyApplicationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventMyApplicationHash();

  @override
  String toString() {
    return r'eventMyApplicationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EventApplication?> $createElement(
    $ProviderPointer pointer,
  ) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<EventApplication?> create(Ref ref) {
    final argument = this.argument as String;
    return eventMyApplication(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventMyApplicationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventMyApplicationHash() =>
    r'bb96a845c65f0ea49701c0cf756ee51e40232e84';

final class EventMyApplicationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EventApplication?>, String> {
  const EventMyApplicationFamily._()
      : super(
          retry: null,
          name: r'eventMyApplicationProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  EventMyApplicationProvider call(String eventId) =>
      EventMyApplicationProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventMyApplicationProvider';
}
