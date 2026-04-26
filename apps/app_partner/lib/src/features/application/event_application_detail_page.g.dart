// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_application_detail_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventApplicationDetail)
const eventApplicationDetailProvider = EventApplicationDetailFamily._();

final class EventApplicationDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<EventApplication?>,
          EventApplication?,
          FutureOr<EventApplication?>
        >
    with
        $FutureModifier<EventApplication?>,
        $FutureProvider<EventApplication?> {
  const EventApplicationDetailProvider._({
    required EventApplicationDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventApplicationDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventApplicationDetailHash();

  @override
  String toString() {
    return r'eventApplicationDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EventApplication?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EventApplication?> create(Ref ref) {
    final argument = this.argument as String;
    return eventApplicationDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventApplicationDetailProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventApplicationDetailHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

final class EventApplicationDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EventApplication?>, String> {
  const EventApplicationDetailFamily._()
    : super(
        retry: null,
        name: r'eventApplicationDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventApplicationDetailProvider call(String applicationId) =>
      EventApplicationDetailProvider._(argument: applicationId, from: this);

  @override
  String toString() => r'eventApplicationDetailProvider';
}
